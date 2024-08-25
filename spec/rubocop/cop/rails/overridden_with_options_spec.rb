# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Rails::OverriddenWithOptions, :config do
  it 'registers an offense when nested `if` condition matches outer `if`' do
    expect_offense(<<~RUBY)
      class Post < ApplicationRecord
        with_options if: :published? do
          validates :content, length: { minimum: 50 }, if: -> { content.present? }
                                                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid nesting the same `if` or `unless` condition inside a `with_options` block. The condition in `with_options` may be overridden. Consider refactoring.
        end
      end
    RUBY
  end

  it 'registers an offense when nested `unless` condition matches outer `unless`' do
    expect_offense(<<~RUBY)
      class Post < ApplicationRecord
        with_options unless: :archived? do
          validates :content, length: { minimum: 50 }, unless: -> { content.blank? }
                                                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid nesting the same `if` or `unless` condition inside a `with_options` block. The condition in `with_options` may be overridden. Consider refactoring.
        end
      end
    RUBY
  end

  it 'registers an offense when both `if` and `unless` conditions are nested and match outer conditions' do
    expect_offense(<<~RUBY)
      class Post < ApplicationRecord
        with_options({ if: :published?, unless: -> { content.blank? } }) do
          validates :content, length: { minimum: 50 }, if: -> { content.present? }
                                                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid nesting the same `if` or `unless` condition inside a `with_options` block. The condition in `with_options` may be overridden. Consider refactoring.
          validates :content, length: { minimum: 50 }, unless: -> { content.blank? }
                                                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid nesting the same `if` or `unless` condition inside a `with_options` block. The condition in `with_options` may be overridden. Consider refactoring.
        end
      end
    RUBY
  end

  it 'registers an offense when nested with_options block overrides conditions' do
    expect_offense(<<~RUBY)
      class Post < ApplicationRecord
        with_options if: :published? do
          with_options if: -> { content.present? } do
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid nesting the same `if` or `unless` condition inside a `with_options` block. The condition in `with_options` may be overridden. Consider refactoring.
            validates :content, length: { minimum: 50 }, if: -> { content.present? }
                                                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid nesting the same `if` or `unless` condition inside a `with_options` block. The condition in `with_options` may be overridden. Consider refactoring.
          end
        end
      end
    RUBY
  end

  it 'does not register an offense when nested `unless` condition differs from outer `if`' do
    expect_no_offenses(<<~RUBY)
      class Post < ApplicationRecord
        with_options if: :published? do
          validates :content, length: { minimum: 50 }, unless: -> { content.blank? }
        end
      end
    RUBY
  end

  it 'does not register an offense when nested `if` condition differs from outer `unless`' do
    expect_no_offenses(<<~RUBY)
      class Post < ApplicationRecord
        with_options unless: :archived? do
          validates :content, length: { minimum: 50 }, if: -> { content.present? }
        end
      end
    RUBY
  end

  it 'does not register an offense for validations outside of with_options block' do
    expect_no_offenses(<<~RUBY)
      class Post < ApplicationRecord
        validates :content, length: { minimum: 50 }, if: -> { content.present? }

        with_options if: :published? do
          validates :title, presence: true
        end
      end
    RUBY
  end

  it 'does not register an offense when `with_options` block is empty' do
    expect_no_offenses(<<~RUBY)
      with_options if: :published? do |merger|
      end
    RUBY
  end

  it 'does not register an offense when calling a method with a receiver in `with_options` without block arguments' do
    expect_no_offenses(<<~RUBY)
      with_options do
        validates :content, length: { minimum: 50 }, if: -> { content.present? }
      end
    RUBY
  end
end
