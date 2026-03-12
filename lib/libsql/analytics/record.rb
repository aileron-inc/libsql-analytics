# frozen_string_literal: true

module Libsql
  module Analytics
    # すべての Analytics モデルの基底クラス。
    # configure 時に establish_connection を呼ぶことで
    # アプリのメイン DB と完全に分離した接続を持つ。
    class Record < ActiveRecord::Base
      self.abstract_class = true
    end
  end
end
