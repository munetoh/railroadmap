# RailroadMap abstraction map file

# same with rake routes
$route_map = [
              'new_user_session' => ['devise/sessions','new','GET','/users/sign_in(.:format)'],
                  'user_session' => ['devise/sessions','create','POST','/users/sign_in(.:format)'],
          'destroy_user_session' => ['devise/sessions','destroy','GET','/users/sign_out(.:format)'],
                 'user_password' => ['devise/passwords','create','POST','/users/password(.:format)'],
             'new_user_password' => ['devise/passwords','new','GET','/users/password/new(.:format)'],
            'edit_user_password' => ['devise/passwords','edit','GET','/users/password/edit(.:format)'],
      'cancel_user_registration' => ['devise/registrations','cancel','GET','/users/cancel(.:format)'],
             'user_registration' => ['devise/registrations','create','POST','/users(.:format)'],
         'new_user_registration' => ['devise/registrations','new','GET','/users/sign_up(.:format)'],
        'edit_user_registration' => ['devise/registrations','edit','GET','/users/edit(.:format)'],
             'user_confirmation' => ['devise/confirmations','create','POST','/users/confirmation(.:format)'],
         'new_user_confirmation' => ['devise/confirmations','new','GET','/users/confirmation/new(.:format)'],
                   'user_unlock' => ['devise/unlocks','create','POST','/users/unlock(.:format)'],
               'new_user_unlock' => ['devise/unlocks','new','GET','/users/unlock/new(.:format)'],
                          'user' => ['users','create','POST','/user(.:format)'],
                      'new_user' => ['users','new','GET','/user/new(.:format)'],
                     'edit_user' => ['users','edit','GET','/user/edit(.:format)'],
                'switch_to_task' => ['tasks','switch_to','POST','/tasks/:id/switch_to(.:format)'],
                         'tasks' => ['tasks','index','GET','/tasks(.:format)'],
                      'new_task' => ['tasks','new','GET','/tasks/new(.:format)'],
                     'edit_task' => ['tasks','edit','GET','/tasks/:id/edit(.:format)'],
                          'task' => ['tasks','show','GET','/tasks/:id(.:format)'],
                          'tags' => ['tags','index','GET','/tags(.:format)'],
                       'new_tag' => ['tags','new','GET','/tags/new(.:format)'],
                      'edit_tag' => ['tags','edit','GET','/tags/:id/edit(.:format)'],
                           'tag' => ['tags','show','GET','/tags/:id(.:format)'],
                          'root' => ['welcome','index','ROOT','/(.:format)'],
]

# for RailroadMap.  pathname in ruby  =>  state id
$path2id = {
              'new_user_session'      => 'C_devise:session#new',
              'new_user_session_path' => 'C_devise:session#new',
              'new_user_session_url'  => 'C_devise:session#new',
                  'user_session'      => 'C_devise:session#create',
                  'user_session_path' => 'C_devise:session#create',
                  'user_session_url'  => 'C_devise:session#create',
          'destroy_user_session'      => 'C_devise:session#destroy',
          'destroy_user_session_path' => 'C_devise:session#destroy',
          'destroy_user_session_url'  => 'C_devise:session#destroy',
                 'user_password'      => 'C_devise:password#create',
                 'user_password_path' => 'C_devise:password#create',
                 'user_password_url'  => 'C_devise:password#create',
             'new_user_password'      => 'C_devise:password#new',
             'new_user_password_path' => 'C_devise:password#new',
             'new_user_password_url'  => 'C_devise:password#new',
            'edit_user_password'      => 'C_devise:password#edit',
            'edit_user_password_path' => 'C_devise:password#edit',
            'edit_user_password_url'  => 'C_devise:password#edit',
      'cancel_user_registration'      => 'C_devise:registration#cancel',
      'cancel_user_registration_path' => 'C_devise:registration#cancel',
      'cancel_user_registration_url'  => 'C_devise:registration#cancel',
             'user_registration'      => 'C_devise:registration#create',
             'user_registration_path' => 'C_devise:registration#create',
             'user_registration_url'  => 'C_devise:registration#create',
         'new_user_registration'      => 'C_devise:registration#new',
         'new_user_registration_path' => 'C_devise:registration#new',
         'new_user_registration_url'  => 'C_devise:registration#new',
        'edit_user_registration'      => 'C_devise:registration#edit',
        'edit_user_registration_path' => 'C_devise:registration#edit',
        'edit_user_registration_url'  => 'C_devise:registration#edit',
             'user_confirmation'      => 'C_devise:confirmation#create',
             'user_confirmation_path' => 'C_devise:confirmation#create',
             'user_confirmation_url'  => 'C_devise:confirmation#create',
         'new_user_confirmation'      => 'C_devise:confirmation#new',
         'new_user_confirmation_path' => 'C_devise:confirmation#new',
         'new_user_confirmation_url'  => 'C_devise:confirmation#new',
                   'user_unlock'      => 'C_devise:unlock#create',
                   'user_unlock_path' => 'C_devise:unlock#create',
                   'user_unlock_url'  => 'C_devise:unlock#create',
               'new_user_unlock'      => 'C_devise:unlock#new',
               'new_user_unlock_path' => 'C_devise:unlock#new',
               'new_user_unlock_url'  => 'C_devise:unlock#new',
                          'user'      => 'C_user#create',
                          'user_path' => 'C_user#create',
                          'user_url'  => 'C_user#create',
                      'new_user'      => 'C_user#new',
                      'new_user_path' => 'C_user#new',
                      'new_user_url'  => 'C_user#new',
                     'edit_user'      => 'C_user#edit',
                     'edit_user_path' => 'C_user#edit',
                     'edit_user_url'  => 'C_user#edit',
                'switch_to_task'      => 'C_task#switch_to',
                'switch_to_task_path' => 'C_task#switch_to',
                'switch_to_task_url'  => 'C_task#switch_to',
                         'tasks'      => 'C_task#index',
                         'tasks_path' => 'C_task#index',
                         'tasks_url'  => 'C_task#index',
                      'new_task'      => 'C_task#new',
                      'new_task_path' => 'C_task#new',
                      'new_task_url'  => 'C_task#new',
                     'edit_task'      => 'C_task#edit',
                     'edit_task_path' => 'C_task#edit',
                     'edit_task_url'  => 'C_task#edit',
                         '@task'      => 'C_task#show',
                          'task'      => 'C_task#show',
                          'task_path' => 'C_task#show',
                          'task_url'  => 'C_task#show',
                          'tags'      => 'C_tag#index',
                          'tags_path' => 'C_tag#index',
                          'tags_url'  => 'C_tag#index',
                       'new_tag'      => 'C_tag#new',
                       'new_tag_path' => 'C_tag#new',
                       'new_tag_url'  => 'C_tag#new',
                      'edit_tag'      => 'C_tag#edit',
                      'edit_tag_path' => 'C_tag#edit',
                      'edit_tag_url'  => 'C_tag#edit',
                          '@tag'      => 'C_tag#show',
                           'tag'      => 'C_tag#show',
                           'tag_path' => 'C_tag#show',
                           'tag_url'  => 'C_tag#show',
                          'root'      => 'C_welcome#index',
                          'root_path' => 'C_welcome#index',
                          'root_url'  => 'C_welcome#index',
   # Added
                'after_confirmation_path_for'   => 'C_welcome#index',
                'after_omniauth_failure_path_for'   => 'C_welcome#index',
                'after_sign_out_path_for'           => 'C_welcome#index',
                'new_registration_path'             => 'C_devise:registration#new',
                'redirect_location'                 => 'C_welcome#index',
                'stored_location_for'  => 'C_welcome#index',
                'confirmation_url'            => 'C_devise:confirmation#unknown',
                'edit_password_url'           => 'C_devise:password#edit',
                'unlock_url'                  => 'C_devise:unlock#new',
                'registration_path'           => 'C_devise:registration#unknown',
                'back'  => 'C_caller',
                'new_session_path'            => 'C_devise:session#new',
                'new_password_path'           => 'C_devise:password#new',
                'new_confirmation_path'       => 'C_devise:confirmation#new',
                'new_unlock_path'             => 'C_devise:unlock#new',
                'omniauth_authorize_path'     => 'C_devise:omniauth_callback#unknown',
                
                
}


# Add transition
#   type,src,dst
$list_additional_transition = [
  ['layout', 'V_welcome#index', 'V_layout#application'],
  ['layout', 'C_devise:session#create', 'V_welcome#index'],
]


# Variables
#$map_variable ={
#      'devise#user_signed_in?' => ['boolean','signed_in'],
#}


# Ruby code to abstracted expression (B method)
$map_guard = {
      '' => '',
      '|format|.size > 0' => 'true',
      '@tag.save == true'                              => 'save==true',
      '@tag.update_attributes(params[:tag]) == true'   => 'update==true',
      '@task.save == true'                             => 'save==true',
      '@task.update_attributes(params[:task]) == true' => 'update==true',
      '@user.save == true'                             => 'save==true',
      '@user.update_attributes(params[:user]) == true' => 'update==true',
      'resource.errors.empty? == true'                 => 'post_error==true',
      'resource.save == true'                          => 'save==true',
      'resource.update_with_password(params[resource_name]) == true' => 'update==true',
      'successful_and_sane?(resource) == true' => 'resource==true',
      'controller_name!="sessions" == true'    => 'TBD', # 'not session controller',
      'devise_mapping.registerable?&&controller_name!="registrations" == true' => 'TBD',
      'devise_mapping.recoverable?&&controller_name!="passwords" == true'      => 'TBD',
      'devise_mapping.confirmable?&&controller_name!="confirmations" == true'  => 'TBD',
      'devise_mapping.lockable?&&resource_class.unlock_strategy_enabled?(:email)&&controller_name!="unlocks" == true' => 'TBD',
      'devise_mapping.omniauthable? == true' => 'TBD',
      'user_signed_in? == true'   => 'signed_in==true',
      '@task.new_record? == true' => 'update==true',
}

# TODO CFRF automatic?
$map_guard_by_block = {
  'V_tag#_form_R' => 'csrf_token==good',
  'V_task#_form_R_B' => 'csrf_token==good',
  'V_devise:unlock#new_R' => 'csrf_token==good',
  'V_devise:confirmation#new_R' => 'csrf_token==good',
  'V_devise:password#edit_R' => 'csrf_token==good',
  'V_devise:password#new_R' => 'csrf_token==good', 
  'V_devise:registration#edit_R' => 'csrf_token==good',
  'V_devise:registration#new_R' => 'csrf_token==good',
  'V_devise:session#new_R' => 'csrf_token==good',
}

# Actions at block
$map_action ={
      #'V_devise:session#new_R' => 'sign_in = authentication(user,password,password_confirmation)',
      'V_devise:session#new_R'       => 'signed_in = true',
      'C_devise:session#destroy_R_D' => 'signed_in = false',
}

# SETS in B model for submit(POST)
# Submit variable <=> SETS in B
$map_bset_types = {
      'email'                 => 'EMAIL',
      'password'              => 'PASSWORD',
      'password_confirmation' => 'PASSWORD',
      'current_password'      => 'PASSWORD',
      'remember_me'           => 'FLAG',
      'title'                 => 'TEXT',
      'description'           => 'TEXT',
      'reset_password_token'  => 'FLAG',
      'name'                  => 'TEXT'
}


# Fix transitions
# Src (in Table)  => valid, dst, type, text, args
$map_fix_transitions = {
  'V_task#index[3]' => [true, 'C_task#switch_to','submit','Again', ''],
  # delete duplications
  'V_devise:password#edit[2]' => [false],
  'V_devise:password#new[2]' => [false],
  'V_devise:confirmation#new[2]' => [false],
  'V_devise:registration#edit[3]' => [false],
  'V_devise:registration#new[2]' => [false],
  'V_devise:session#new[2]' => [false],
  'V_devise:unlock#new[2]' => [false],
  #'' => [false],
  #'' => [false],
  #'' => [false],
  
  
  
  
}


# EOF
