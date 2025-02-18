
require_relative '../assistants/architect_assistant'

RSpec.describe ArchitectAssistant do
  let(:assistant) { ArchitectAssistant.new }

  it 'creates a city with the correct attributes' do
    result = assistant.create_city('FutureCity', 100000, 500, 5)
    expect(result).to include('FutureCity')
  end

  it 'designs a skyscraper with green certification' do
    result = assistant.design_skyscraper(500, 'Glass', 'Platinum')
    expect(result).to include('Platinum')
  end
end
