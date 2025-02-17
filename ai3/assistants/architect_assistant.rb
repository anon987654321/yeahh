require 'rails'
#!/usr/bin/env ruby
require_relative '__shared.sh'

class ArchitectAssistant
class ArchitectAssistant
class ArchitectAssistant
class ArchitectAssistant
class ArchitectAssistant
class ArchitectAssistant
class ArchitectAssistant
class ArchitectAssistant
  def initialize
  def initialize
  def initialize
  def initialize
  def initialize
  def initialize
  def initialize
  def initialize
attr_accessor :memory
attr_accessor :knowledge_sources
      "https://archdaily.com/",
      "https://designboom.com/architecture/",
      "https://dezeen.com/",
      "https://archinect.com/"
    ]
  end
  def gather_inspiration
  def gather_inspiration
  def gather_inspiration
  def gather_inspiration
  def gather_inspiration
  def gather_inspiration
  def gather_inspiration
  def gather_inspiration
    @knowledge_sources.each do |url|
    @knowledge_sources.each { |url|
      logger.info "Fetching architecture insights from: #{url}"
  def create_design
  def create_design
  def create_design
  def create_design
  def create_design
  def create_design
  def create_design
  def create_design
# prompt = "Generate a concept design inspired by mo... (brief explanation of complex logic)
    prompt = "Generate a concept design inspired by modern architecture trends."
    puts format_prompt(create_prompt(prompt, []), {})
