#
#  Devise
#

module Rails
  class Devise
    def initialize
    end
    
    def add_variable
      p = Abstraction::Parser::AstParser.new
      p.add_variable('devise', 'devise#user_signed_in?', 'string', 'model/dummy.rb')

      $map_variable = Hash.new if $map_variable == nil
      
      $map_variable['devise#user_signed_in?'] = ['boolean','signed_in']

      $log.info "Added variables, devise#user_signed_in? for devise. "
      # TODO add this app/model/user
        #  devise :database_authenticatable, :registerable, #:encryptable,
        #     :recoverable, :rememberable, :trackable, :validatable,
        #     :confirmable, :lockable, :token_authenticatable
        #p.add_variable('devise', 'user#remember_me', 'boolean', 'model/hoge.rb')
    end
    
  end
end