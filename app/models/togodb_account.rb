class TogodbAccount < ApplicationRecord
  has_many :tables, class_name: 'TogodbTable', foreign_key: 'creator_id'
  has_many :roles, class_name: 'TogodbRole', foreign_key: 'user_id', dependent: :destroy

  include ActsAsBits
  acts_as_bits :flags, %w[superuser import_table]

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[github google_oauth2]

  # TODO: githubでは Profile > Public email が設定していないと auth.info.email が null になる
  class << self
    def from_omniauth(auth)
      puts auth.info
      where(provider: auth.provider, uid: auth.uid).first_or_create do |togodb_account|
        togodb_account.oauth_name = auth.info.name
        togodb_account.email = auth.info.email
        togodb_account.password = Devise.friendly_token[0, 20]
      end
    end

    def create_unique_string
      SecureRandom.uuid
    end
  end

  def email_required?
    # TODO ユーザーがOAuthのauthenticationsを持っていないときはどう判定する？
    # (authentications.empty? || !email.blank?) && super
    false
  end

  def in_environment_where_condition
    case Togodb.environment
    when 'test'
      { environment: 0 }
    when 'production'
      { environment: 1 }
    else
      {}
    end
  end

  def configurable_tables(order = 'name')
    if superuser?
      TogodbTable.where(in_environment_where_condition).order(order)
    else
      my_table_ids = TogodbTable.where(creator_id: id).map(&:id)
      executable_table_ids = TogodbRole.executable_table_ids(id)
      TogodbTable.where(in_environment_where_condition.merge(
                          id: my_table_ids + executable_table_ids
                        )).order(order)
    end
  end

  def readable_configurable_tables(order = 'name')
    if superuser?
      # TODO togodb_tablesが綺麗な場合は、creator_idで絞り込む必要はない
      TogodbTable.where(creator_id: TogodbAccount.all.map(&:id)).order(order)
    else
      my_table_ids = TogodbTable.where(creator_id: id).map(&:id)
      executable_table_ids = TogodbRole.executable_table_ids(id)
      readable_table_ids = TogodbRole.readable_table_ids(id)
      TogodbTable.where(in_environment_where_condition.merge(
                          id: my_table_ids + executable_table_ids + readable_table_ids
                        )).order(order)
    end
  end

  def active?
    !deleted
  end

  def local_account?
    #--> login == 'guest' || !password.blank?
    provider.nil?
  end

  def guest_user?
    login == 'guest'
  end

  def write_table?(table)
    return false unless table.exist_in_environment?
    return true if superuser
    return true if id == table.creator_id

    role = TogodbRole.find_by(table_id: table.id, user_id: id)
    if role.nil?
      false
    else
      role.role_admin || role.role_write
    end
  end

  def read_table?(table)
    return false unless table.exist_in_environment?
    return true if superuser
    return true if id == table.creator_id

    role = TogodbRole.find_by(table_id: table.id, user_id: id)
    if role.nil?
      false
    else
      role.role_admin || role.role_read
    end
  end

  def execute_table?(table)
    return true if superuser
    return false unless table.exist_in_environment?
    return true if id == table.creator_id

    role = TogodbRole.find_by(table_id: table.id, user_id: id)
    if role.nil?
      false
    else
      role.role_admin || role.role_execute
    end
  end

  def admin_table?(table)
    return false unless table.exist_in_environment?
    return true if superuser
    return true if id == table.creator_id

    role = TogodbRole.find_by(table_id: table.id, user_id: id)
    if role.nil?
      false
    else
      role.role_admin
    end
  end

  def role_for_disp
    if superuser?
      'Super User'
    elsif import_table?
      'Import Table'
    else
      '-'
    end
  end

  def login
    if local_account?
      "#{name} [Local account]"
    else
      "#{oauth_name} [#{provider_name}]"
    end
  end

  def provider_name
    case provider
    when 'google_oauth2'
      'Google'
    when 'github'
      'Github'
    else
      provider
    end
  end
end
