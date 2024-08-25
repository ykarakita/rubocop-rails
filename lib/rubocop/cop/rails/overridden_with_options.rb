# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      class OverriddenWithOptions < Base
        extend AutoCorrector

        MSG = 'Avoid nesting the same `if` or `unless` condition inside a `with_options` block. ' \
              'The condition in `with_options` may be overridden. Consider refactoring.'
        CONDITIONAL_KEYS = %i[if unless].freeze

        # Match `with_options` blocks
        def_node_matcher :with_options_block, <<~PATTERN
          (block
            (send nil? :with_options (hash $...))
            (args _?) ...)
        PATTERN

        # Match methods that can use `if:` or `unless:` options
        def_node_matcher :method_with_condition_option, <<~PATTERN
          (send nil? _ (hash <$(pair (sym {:if :unless}) _) ...>))
        PATTERN

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          check_with_options_block(node, [])
        end

        private

        # 再帰的に`with_options`ブロックを検査
        def check_with_options_block(node, parent_conditions)
          with_options_block(node) do |options_pairs|
            # 現在の`with_options`の条件を取得し、親の条件と結合
            current_conditions = extract_condition_pairs(options_pairs)
            all_conditions = parent_conditions + current_conditions.map { _1.key.value }

            return if current_conditions.empty?

            # ブロック内のすべてのメソッド呼び出しを検査
            node.each_descendant(:send) do |send_node|
              method_with_condition_option(send_node) do |condition_pair|
                next unless all_conditions.include?(condition_pair.key.value)

                add_offense(condition_pair) do |corrector|
                  corrector.insert_before(send_node, '# Consider refactoring: ')
                end
              end
            end

            # ネストされた`with_options`ブロックを再帰的に処理
            node.each_child_node(:block) do |nested_block|
              check_with_options_block(nested_block, all_conditions.map { _1.key.value })
            end
          end
        end

        # `if`や`unless`条件を抽出
        def extract_condition_pairs(pairs)
          pairs.filter_map do |pair|
            key, _value = *pair
            pair if CONDITIONAL_KEYS.include?(key.value)
          end
        end
      end
    end
  end
end
