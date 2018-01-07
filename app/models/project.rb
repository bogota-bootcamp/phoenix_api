class Project < ApplicationRecord
  #before_save :update_fee
  before_update :update_month

  belongs_to :investor, optional: true
  belongs_to :account, optional: true
  belongs_to :client
  has_many :receipts
  has_many :matches
  has_many :investors, through: :matches

  scope :include_investor, -> { includes(:investor) }
  scope :include_account, -> { includes(:account )}
  scope :include_client, -> { includes(:client )}
  scope :include_receipts, -> { includes(:receipts )}
  scope :by_client, -> (id:) {where(client_id: id) }
  scope :by_investor, -> (id:) { where(investor_id: id).where(approved: true) }
  scope :by_account, -> (id:) { where(account_id: id) }
  scope :by_price, -> (price_start:,price_end:) { where(money: price_start..price_end) }
  scope :by_interest, -> (interest_start:,interest_end:) { where(interest_rate: interest_start..interest_end) }
  scope :by_time, -> (time_start:,time_end:) { where(month: time_start..time_end) }


  validates_presence_of :dream, :description,:money,:monthly_payment,:month
  validates_numericality_of :money,:monthly_payment,:month, only_integer: true
  validates_numericality_of :month
  validate :validate_number

  def self.load(page:1 ,per_page: 10)
    paginate(page: page, per_page: per_page)
  end

  def self.by_id(id)
    find_by_id(id)
  end

  def self.add_receipt(project, params)
    r = Receipt.new(params)
    r.project_id = project
    r.save
  end

  private
  def update_month
    if self.changed.include?("interest_rate") || self.changed.include?("monthly_payment") || self.changed.include?("money")
      period = 0
      is_creating = true
      money_temp = self.money + 0.0
      while is_creating
        period = period + 1
        interest_temp = (self.interest_rate/100.0)*money_temp
        payment = self.monthly_payment - interest_temp
        if money_temp >= @project.monthly_payment
          money_temp = money_temp - payment
        else
          money_temp = 0
        end

        if money_temp == 0
          is_creating = false
        end
      end
      self.month = period
    end
  end
  def validate_number
    errors.add(:money, "can't be negative") if self.money && self.money < 0
    errors.add(:monthly_payment, "can't be negative") if self.monthly_payment && self.monthly_payment < 0
    errors.add(:month, "can't be negative") if self.month && self.month < 0
    errors.add(:interest_rate, "can't be negative") if self.interest_rate && self.interest_rate < 0
  end
end
