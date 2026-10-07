# frozen_string_literal: true

module Wallflower
  class Engine < ::Rails::Engine
    isolate_namespace Wallflower

    config.after_initialize { Wallflower.check_kinds! }
  end
end
