
require_relative '../assistants/manufacturing_assistant'

RSpec.describe ManufacturingAssistant do
  let(:assistant) { ManufacturingAssistant.new }

  it 'designs a space plane with the correct attributes' do
    result = assistant.design_space_plane('Ion', 50, 8)
    expect(result).to include('Ion')
  end

  it 'prints a car model with the correct specifications' do
    result = assistant.print_car('Model X', 'Electric', 5)
    expect(result).to include('Electric')
  end
end
