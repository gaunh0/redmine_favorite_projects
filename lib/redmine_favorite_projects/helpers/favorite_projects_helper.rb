module RedmineFavoriteProjects
  module Helper

    def favorite_project_tag_url(tag_name, options={})
      {:controller => 'favorite_projects',
       :action => 'search',
       :set_filter => 1,
       :fields => [:tags],
       :values => {:tags => [tag_name]},
       :operators => {:tags => '='}
      }.merge(options)
    end

    def favorite_project_tag_link(tag_name, options={})
      style = RedmineFavoriteProjects.settings[:monochrome_tags].to_i > 0 ? {} : {:style => "background-color: #{favorite_project_tag_color(tag_name)}"}
      tag_count = options.delete(:count)
      tag_title = tag_count ? "#{tag_name} (#{tag_count})" : tag_name
      link = link_to tag_title, favorite_project_tag_url(tag_name), options
      content_tag(:span, link, {:class => "tag-label-color"}.merge(style))
    end

    def favorite_project_tag_color(tag_name)
      "##{"%06x" % (tag_name.unpack('H*').first.hex % 0xffffff)}"
      # "##{"%06x" % (Digest::MD5.hexdigest(tag_name).hex % 0xffffff)}"
      # "##{"%06x" % (tag_name.hash % 0xffffff).to_s}"
    end

    def favorite_project_tag_links(tag_list, options={})
      content_tag(
                :span,
                tag_list.map{|tag| favorite_project_tag_link(tag, options)}.join(' ').html_safe,
                :class => "tag_list") if tag_list
    end
  end
end

ActionView::Base.send :include, RedmineFavoriteProjects::Helper
