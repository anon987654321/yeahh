
require_relative '../assistants/music_assistant'

RSpec.describe MusicAssistant do
  let(:assistant) { MusicAssistant.new }

  it 'creates a music artist with the correct instruments' do
    result = assistant.create_artist('DJ Future', 'Electronic', ['Synthesizer', 'Drums'])
    expect(result).to include('DJ Future')
  end

  it 'generates a track with the correct tempo' do
    result = assistant.generate_track('DJ Future', 120, 'Happy', 4)
    expect(result).to include('120 BPM')
  end
end
