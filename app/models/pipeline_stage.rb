# frozen_string_literal: true

class PipelineStage < ApplicationRecord
  belongs_to :account, class_name: "Tenancy::Account"
  has_many :opportunities, class_name: "CRM::Opportunity", dependent: :nullify

  validates :name, presence: true
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :probability, presence: true, numericality: { in: 0..100 }
  validates :color, presence: true, format: { with: /\A#[0-9a-fA-F]{6}\z/ }

  scope :ordered, -> { order(:position) }

  after_create :reorder_positions

  private

  def reorder_positions
    return unless account

    account.pipeline_stages.ordered.each_with_index do |stage, index|
      stage.update_column(:position, index + 1) if stage.position != index + 1
    end
  end
end