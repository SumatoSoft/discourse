require_dependency 'sass/discourse_stylesheets'
require_dependency 'distributed_cache'

class ColorScheme < ActiveRecord::Base

  def self.themes
    base_with_hash = {}
    base_colors.each do |name, color|
      base_with_hash[name] = "##{color}"
    end

    [
      { id: 'default', colors: base_with_hash },
      {
        id: 'dark',
        colors: {
          "primary" =>           '#dddddd',
          "secondary" =>         '#222222',
          "tertiary" =>          '#0f82af',
          "quaternary" =>        '#c14924',
          "header_background" => '#111111',
          "header_primary" =>    '#333333',
          "highlight" =>         '#a87137',
          "danger" =>            '#e45735',
          "success" =>           '#1ca551',
          "love" =>              '#028ace'
        }
      }
    ]
  end

  def self.hex_cache
    @hex_cache ||= DistributedCache.new("scheme_hex_for_name")
  end

  attr_accessor :is_base

  has_many :color_scheme_colors, -> { order('id ASC') }, dependent: :destroy

  alias_method :colors, :color_scheme_colors

  scope :current_version, ->{ where(versioned_id: nil) }

  after_destroy :destroy_versions
  after_save :publish_discourse_stylesheet
  after_save :dump_hex_cache
  after_destroy :dump_hex_cache

  validates_associated :color_scheme_colors

  BASE_COLORS_FILE = "#{Rails.root}/app/assets/stylesheets/common/foundation/colors.scss"

  @mutex = Mutex.new

  def self.base_colors
    @mutex.synchronize do
      return @base_colors if @base_colors
      @base_colors = {}
      File.readlines(BASE_COLORS_FILE).each do |line|
        matches = /\$([\w]+):\s*#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})(?:[;]|\s)/.match(line.strip)
        @base_colors[matches[1]] = matches[2] if matches
      end
    end
    @base_colors
  end

  def self.enabled
    current_version.find_by(enabled: true)
  end

  def self.base
    return @base_color_scheme if @base_color_scheme
    @base_color_scheme = new(name: I18n.t('color_schemes.base_theme_name'), enabled: false)
    @base_color_scheme.colors = base_colors.map { |name, hex| {name: name, hex: hex} }
    @base_color_scheme.is_base = true
    @base_color_scheme
  end

  # create_from_base will create a new ColorScheme that overrides Discourse's base color scheme with the given colors.
  def self.create_from_base(params)
    new_color_scheme = new(name: params[:name])
    colors = base.colors_hashes

    # Override base values
    params[:colors].each do |name, hex|
      c = colors.find {|x| x[:name].to_s == name.to_s}
      c[:hex] = hex
    end

    new_color_scheme.colors = colors
    new_color_scheme.save
    new_color_scheme
  end

  def self.lookup_hex_for_name(name)
    Discourse.plugin_themes.each do |pt|
      if pt.color_scheme
        found = pt.color_scheme[name.to_sym]
        return found if found
      end
    end

    # Can't use `where` here because base doesn't allow it
    (enabled || base).colors.find {|c| c.name == name }.try(:hex) || :nil
  end

  def self.hex_for_name(name)
    hex_cache[name] ||= lookup_hex_for_name(name)
    hex_cache[name] == :nil ? nil : hex_cache[name]
  end

  def colors=(arr)
    @colors_by_name = nil
    arr.each do |c|
      self.color_scheme_colors << ColorSchemeColor.new( name: c[:name], hex: c[:hex] )
    end
  end

  def colors_by_name
    @colors_by_name ||= self.colors.inject({}) { |sum,c| sum[c.name] = c; sum; }
  end
  def clear_colors_cache
    @colors_by_name = nil
  end

  def colors_hashes
    color_scheme_colors.map do |c|
      {name: c.name, hex: c.hex}
    end
  end

  def previous_version
    ColorScheme.where(versioned_id: self.id).where('version < ?', self.version).order('version DESC').first
  end

  def destroy_versions
    ColorScheme.where(versioned_id: self.id).destroy_all
  end

  def publish_discourse_stylesheet
    MessageBus.publish("/discourse_stylesheet", self.name)
    DiscourseStylesheets.cache.clear
  end

  def dump_hex_cache
    self.class.hex_cache.clear
  end

end

# == Schema Information
#
# Table name: color_schemes
#
#  id           :integer          not null, primary key
#  name         :string           not null
#  enabled      :boolean          default(FALSE), not null
#  versioned_id :integer
#  version      :integer          default(1), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  via_wizard   :boolean          default(FALSE), not null
#  theme_id     :string
#
