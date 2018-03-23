# frozen_string_literal: true

module RuboCop
  module Cop
    module Metrics
      # This cop checks that the ABC size of methods is not higher than the
      # configured maximum. The ABC size is based on assignments, branches
      # (method calls), and conditions. See http://c2.com/cgi/wiki?AbcMetric
      class AbcSize < Cop
        include MethodComplexity

        MSG = 'Assignment Branch Condition size for %<method>s is too high. ' \
          '[%<complexity>.4g/%<max>.4g] a: %<a>.4g, b: %<b>.4g, c: %<c>.4g'.freeze
        BRANCH_NODES = %i[send csend].freeze
        CONDITION_NODES = CyclomaticComplexity::COUNTED_NODES.freeze

        private

        def check_complexity(node, method_name)
          # Accepts empty methods always.
          return unless node.body

          max = cop_config['Max']
          result = complexity(node.body)

          return unless result[:complexity] > max

          msg = format(self.class::MSG,
                       method: method_name,
                       complexity: result[:complexity],
                       a: result[:a],
                       b: result[:b],
                       c: result[:c],
                       max: max)

          add_offense(node, message: msg) do
            self.max = result[:complexity].ceil
          end
        end

        def complexity(node)
          assignment = 0
          branch = 0
          condition = 0

          node.each_node do |child|
            if child.assignment?
              assignment += 1
            elsif BRANCH_NODES.include?(child.type)
              branch += 1
            elsif CONDITION_NODES.include?(child.type)
              condition += 1
            end
          end

          {
            a: assignment,
            b: branch,
            c: condition,
            complexity: Math.sqrt(assignment**2 + branch**2 + condition**2).round(2)
          }
        end
      end
    end
  end
end
