task 'add_contact_us' => :environment do
  def create_static_page_topic(site_setting_key, title_key, body_key, body_override, category, description, params={})
    unless SiteSetting.send(site_setting_key) > 0
      creator = PostCreator.new( Discourse.system_user,
                                 title: I18n.t(title_key, default: I18n.t(title_key, locale: :en)),
                                 raw: body_override.present? ? body_override : I18n.t(body_key, params.merge(default: I18n.t(body_key, params.merge(locale: :en)))),
                                 skip_validations: true,
                                 category: category ? category.name : nil)
      post = creator.create

      raise "Failed to create the #{description} topic! #{creator.errors.full_messages.join('. ')}" if creator.errors.present?

      SiteSetting.send("#{site_setting_key}=", post.topic_id)

      reply = PostCreator.create( Discourse.system_user,
                                  raw: I18n.t('static_topic_first_reply', page_name: I18n.t(title_key, default: I18n.t(title_key, locale: :en))),
                                  skip_validations: true,
                                  topic_id: post.topic_id )
    end
  end
  create_static_page_topic('contacts_topic_id', 'contacts_topic.title', "contacts_topic.body", nil, Category.find_by(id: SiteSetting.staff_category_id), "contacts")
end
