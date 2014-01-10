# == Schema Information
#
# Table name: organizations
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  code       :string(255)      not null
#  active     :boolean          default(TRUE), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'spec_helper'

describe Organization do
  it { should have_many(:hosts) }
  
  it { should validate_presence_of(:code) }
  it { should validate_uniqueness_of(:code) }
  
  describe "#ensure_code" do
    it "creates a url-safe version of #name" do
      org = Organization.new
      org.name = 'Test Practice 1'
      org.code = nil
      expect(org.valid?).to be_true
      expect(org.code).to eq 'test-practice-1'
    end
    
    it "makes sure #code is never nil after validation (as long as name is set)" do
      org = Organization.new
      org.name = 'Testing 123'
      org.code = nil
      expect(org.code).to be_nil
      expect(org.valid?).to be_true
      expect(org.code).not_to be_nil
    end
    
    it "auto-increments generated #code (test2, test3, etc.) to work around conflicts" do
      org = Organization.first
      
      org2 = Organization.new
      org2.name = org.code
      org2.code = nil
      expect(org2.valid?).to be_true
      expect(org2.code).to eq "#{org.code}2"
    end
  end
  
  describe "create_with_database" do
    it "creates a new organization and creates database" do
      org = nil
      expect {
        org = Organization.create_with_database('createusingdefaultstest', nil)
      }.to change(Organization, :count).by(1)
      org.drop_database!
      org.destroy
    end
  end
  
end
