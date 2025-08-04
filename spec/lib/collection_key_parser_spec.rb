require 'rails_helper'
require_relative '../../lib/collection_key_parser'

RSpec.describe CollectionKeyParser do
  describe '.get_timeline_years' do
    it 'returns 1 for code "N"' do
      expect(described_class.get_timeline_years('N')).to eq(1)
    end

    it 'returns 1 for invalid or short codes' do
      expect(described_class.get_timeline_years('')).to eq(1)
      expect(described_class.get_timeline_years(nil)).to eq(1)
      expect(described_class.get_timeline_years('X')).to eq(1)
      expect(described_class.get_timeline_years('R7')).to eq(1)
    end

    it 'returns correct years for valid codes' do
      expect(described_class.get_timeline_years('R1')).to eq(1)
      expect(described_class.get_timeline_years('R3')).to eq(3)
      expect(described_class.get_timeline_years('R5')).to eq(5)
      expect(described_class.get_timeline_years('E1')).to eq(1)
      expect(described_class.get_timeline_years('E3')).to eq(3)
      expect(described_class.get_timeline_years('E5')).to eq(5)
    end
  end

  describe '.get_employer_count' do
    it 'returns 1 for invalid or non-EN codes' do
      expect(described_class.get_employer_count('N')).to eq(1)
      expect(described_class.get_employer_count('EN')).to eq(1)
      expect(described_class.get_employer_count('EN4')).to eq(1)
      expect(described_class.get_employer_count('E1')).to eq(1)
    end

    it 'returns correct count for valid EN codes' do
      expect(described_class.get_employer_count('EN1')).to eq(1)
      expect(described_class.get_employer_count('EN2')).to eq(2)
      expect(described_class.get_employer_count('EN3')).to eq(3)
    end
  end

  describe '.parse_collection_key' do
    let(:valid_key) { 'en-EPA-DTB-R3-EN2-E-P-W' }

    it 'parses valid key correctly' do
      result = described_class.parse_collection_key(valid_key)
      expect(result[:language]).to eq('en')
      expect(result[:facets]).to eq(['EPA', 'DTB', 'R3', 'EN2', 'E', 'P', 'W'])
    end

    it 'raises error for invalid key format' do
      expect { described_class.parse_collection_key('en-EPA-DTB') }.to raise_error(ArgumentError, 'Invalid collection key: must have 8 facets separated by -')
      expect { described_class.parse_collection_key('e-EPA-DTB-R3-EN2-E-P-W') }.to raise_error(ArgumentError, 'Invalid language code: must be 2 characters')
      expect { described_class.parse_collection_key(123) }.to raise_error(ArgumentError, 'Invalid collection key: must be a string with at least 8 facets')
    end

    it 'raises error for invalid residence code' do
      expect { described_class.parse_collection_key('en-EPA-DTB-R7-EN2-E-P-W') }.to raise_error(ArgumentError, 'Invalid residence code: must be N or R followed by 1, 3, or 5')
    end

    it 'raises error for invalid employment code' do
      expect { described_class.parse_collection_key('en-EPA-DTB-R3-EN4-E-P-W') }.to raise_error(ArgumentError, 'Invalid employment code: must be N, E followed by 1, 3, 5, or EN followed by 1, 2, 3')
    end

    it 'raises error for invalid education code' do
      expect { described_class.parse_collection_key('en-EPA-DTB-R3-EN2-X-P-W') }.to raise_error(ArgumentError, 'Invalid education code: must be E or N')
    end

    it 'raises error for invalid professional license code' do
      expect { described_class.parse_collection_key('en-EPA-DTB-R3-EN2-E-X-W') }.to raise_error(ArgumentError, 'Invalid professional license code: must be P or N')
    end
  end

  describe '.get_requirements' do
    let(:valid_key) { 'en-EPA-DTB-R3-EN2-E-P-W' }
    let(:result) { described_class.get_requirements(valid_key) }

    it 'returns correct Requirements structure for valid key' do
      expect(result.language).to eq('en')

      # Personal Info
      expect(result.verification_steps.personal_info.enabled).to be true
      expect(result.verification_steps.personal_info.modes.to_h).to eq({
        email: true,
        phone: true,
        full_name: false,
        name_alias: true
      })

      # Residence History
      expect(result.verification_steps.residence_history.enabled).to be true
      expect(result.verification_steps.residence_history.years).to eq(3)

      # Employment History
      expect(result.verification_steps.employment_history.enabled).to be true
      expect(result.verification_steps.employment_history.mode).to eq('employers')
      expect(result.verification_steps.employment_history.modes.to_h).to eq({ years: nil, employers: 2 })

      # Education
      expect(result.verification_steps.education.enabled).to be true

      # Professional License
      expect(result.verification_steps.professional_license.enabled).to be true

      # Consents
      expect(result.consents_required.to_h).to eq({
        driver_license: true,
        drug_test: true,
        biometric: true
      })

      # Signature
      expect(result.signature.required).to be true
      expect(result.signature.mode).to eq('wet')
    end

    it 'handles disabled steps correctly' do
      key = 'en-N-N-N-N-N-N-N'
      result = described_class.get_requirements(key)

      expect(result.verification_steps.personal_info.enabled).to be false
      expect(result.verification_steps.residence_history.enabled).to be false
      expect(result.verification_steps.employment_history.enabled).to be false
      expect(result.verification_steps.education.enabled).to be false
      expect(result.verification_steps.professional_license.enabled).to be false
      expect(result.consents_required.to_h).to eq({ driver_license: false, drug_test: false, biometric: false })
      expect(result.signature.required).to be false
      expect(result.signature.mode).to eq('none')
    end

    it 'handles years-based employment history' do
      key = 'en-EPA-DTB-R3-E3-E-P-C'
      result = described_class.get_requirements(key)
      expect(result.verification_steps.employment_history.mode).to eq('years')
      expect(result.verification_steps.employment_history.modes.to_h).to eq({ years: 3, employers: nil })
    end
  end
end