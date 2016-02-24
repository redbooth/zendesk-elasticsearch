Whatsup::Application.routes.draw do
  get  'index/index'
  get  'index/find_tickets' => 'index#update_search_results'
  root 'index#index', as: 'index'
end
