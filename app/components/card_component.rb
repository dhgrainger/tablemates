class CardComponent < ViewComponent::Base
  renders_one :actions

  def initialize(title: nil, id: nil)
    @title = title
    @id = id
  end

  erb_template <<~ERB
    <section class="card border border-base-300 bg-base-100" <% if @id %>id="<%= @id %>"<% end %>>
      <div class="card-body gap-3 p-5">
        <% if @title || actions? %>
          <div class="flex items-center justify-between gap-3">
            <% if @title %><h2 class="card-title text-xl"><%= @title %></h2><% end %>
            <%= actions %>
          </div>
        <% end %>
        <%= content %>
      </div>
    </section>
  ERB
end
