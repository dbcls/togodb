require 'acts_as_bits'

class TogodbUser < ApplicationRecord
  has_many :tables, class_name: 'TogodbTable', foreign_key: 'creator_id'
  has_many :roles, class_name: 'TogodbRole', foreign_key: 'user_id', dependent: :destroy

  include ActsAsBits
  acts_as_bits :flags, %w[superuser import_table]

  class << self

    def authorize(login, password)
      user = find_by_login(login.to_s)

      if user.nil? || !user.local_account? || decrypt(user.password.to_s) != password.to_s
        nil
      else
        user
      end
    end

    def regist(login, password = nil, superuser = false)
      user = find_by_login(login)
      if user.nil?
        user = new
        user.login = login
        user.password = password.nil? ? nil : encrypt(password.to_s)
        user.superuser = superuser
        user.import_table = true
        user.save!
      end

      user
    end

    def reset_root_account
      root = find_by_login('root')
      if root.nil?
        root = TogodbUser.new
      end

      root.login = 'root'
      root.password = encrypt('root')
      root.superuser = true
      root.import_table = true

      root.save!
    end

    def encrypt(password)
      crypt = ActiveSupport::MessageEncryptor.new(SECURE, cipher: CIPHER)
      crypt.encrypt_and_sign(password)
    end

    def decrypt(password)
      crypt = ActiveSupport::MessageEncryptor.new(SECURE, cipher: CIPHER)
      crypt.decrypt_and_verify(password)
    end

  end


  def configurable_tables(order = 'name')
    if superuser?
      TogodbTable.all.order(order)
    else
      my_table_ids = TogodbTable.where(creator_id: id).map(&:id)
      executable_table_ids = TogodbRole.executable_table_ids(id)
      TogodbTable.where(id: my_table_ids + executable_table_ids).order(order)
    end
  end

  def active?
    !deleted
  end

  def local_account?
    login == 'guest' || !password.blank?
  end

  def guest_user?
    login == 'guest'
  end

  def write_table?(table)
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
    return true if id == table.creator_id

    role = TogodbRole.find_by(table_id: table.id, user_id: id)
    if role.nil?
      false
    else
      role.role_admin || role.role_execute
    end
  end

  def admin_table?(table)
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

  def inspect
    #if /\Ahttps?:\/\/openid\.dbcls\.jp\/user\/(.+)/ =~ login
    #  "#{$1} (OpenID)"
    #else
    #  login
    #end
    login
  end

  def decrypt_password
    TogodbUser.decrypt(password)
  end

end
