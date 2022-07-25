module Jekyll
  module Tags
    class CollapseTag < Liquid::Block
      def initialize(tag_name, block_options, liquid_options)
        super
        @title = block_options.strip
      end

      def render(context)
        accordionID = context["accordionID"]
        idx = context["collapsed_idx"]
        collapsedID = "#{accordionID}-collapse-#{idx}"
        headingID = "#{accordionID}-heading-#{idx}"

        # increment for the next collapsible
        context["collapsed_idx"] = idx + 1

        # fist one is open
        collapsed = idx == 1 ? '' : 'collapsed'
        show = idx == 1 ? 'show' : ''

        site = context.registers[:site]
        content = super

        output = <<~EOS
          <div class="accordion-container">
            <div id="#{headingID}">
              <h2 class="mb-0">
                <button class="accordion-btn #{collapsed}" data-toggle="collapse" data-target="##{collapsedID}" aria-expanded="false" aria-controls="#{collapsedID}">
                  <span class="collapse-title">#{@title}</span>
                  <span aria-hidden="true" class="fas fa-chevron-up"></span>
                </button>
              </h2>
            </div>
            <div id="#{collapsedID}" class="accordion-content collapse #{show}" aria-labelledby="#{headingID}" data-parent="##{accordionID}">
              #{content}
            </div>
          </div>
        EOS

        output
      end
    end
  end
end

Liquid::Template.register_tag('collapsible', Jekyll::Tags::CollapseTag)