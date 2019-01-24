# frozen_string_literal: true

require 'rails_helper'
require 'active_fedora/cleaner'

RSpec.describe ModularImporter do
  let(:one_line_example)       { 'spec/fixtures/one_line_example.csv' }
  let(:modular_csv)     { 'spec/fixtures/modular_input.csv' }
  let(:user) { ::User.batch_user }

  before do
    DatabaseCleaner.clean
    ActiveFedora::Cleaner.clean!
  end

  it "imports a csv" do
    expect { ModularImporter.new(modular_csv).import }.to change { Image.count }.by 3
  end

  it "puts the title into the title field" do
    ModularImporter.new(modular_csv).import
    expect(Image.where(title: 'A Cute Dog').count).to eq 1
  end

  it "puts the url into the source field" do
    ModularImporter.new(modular_csv).import
    expect(Image.where(source: 'https://www.pexels.com/photo/animal-blur-canine-close-up-551628/').count).to eq 1
  end

  # it "creates publicly visible objects" do
  #   ModularImporter.new(modular_csv).import
  #   imported_image = Image.first
  #   expect(imported_image.visibility).to eq 'open'
  # end

  # it "attaches a file" do
  #   ModularImporter.new(modular_csv).import
  #   imported_image = Image.first
  #   expect(imported_image.members.first).to be_instance_of(FileSet)
  #   expect(imported_image.members.first.title.first).to eq 'dog.jpg'
  # end
end
