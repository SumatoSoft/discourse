class BasicUserSerializer < ApplicationSerializer
  attributes :id, :username, :avatar_template, :online

  def include_name?
    SiteSetting.enable_names?
  end

  def online
    user.is_a?(PostAction) ? user.user.online? : user.try(:online?)
  end

  def avatar_template
    if Hash === object
      User.avatar_template(user[:username], user[:uploaded_avatar_id])
    else
      user.try(:avatar_template)
    end
  end

  def user
    object[:user] || object
  end

end
