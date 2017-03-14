module ConfigurableUrls

  def faq_path
    SiteSetting.faq_url.blank? ? "#{Discourse::base_uri}/faq" : SiteSetting.faq_url
  end

  def tos_path
    SiteSetting.tos_url.blank? ? "#{Discourse::base_uri}/tos" : SiteSetting.tos_url
  end

  def privacy_path
    SiteSetting.privacy_policy_url.blank? ? "#{Discourse::base_uri}/privacy" : SiteSetting.privacy_policy_url
  end

  def contacts_path
    SiteSetting.contacts_url.blank? ? "#{Discourse::base_uri}/contacts" : SiteSetting.contacts_url
  end

end
