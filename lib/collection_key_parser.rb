# frozen_string_literal: true

# CollectionKeyParser module for parsing collection keys and extracting requirements
module CollectionKeyParser
  # Requirements structure to hold parsed requirements
  class Requirements
    attr_accessor :language, :verification_steps, :consents_required, :signature

    def initialize
      @verification_steps = VerificationSteps.new
      @consents_required = ConsentsRequired.new
      @signature = Signature.new
    end
  end

  # VerificationSteps structure to hold verification steps
  class VerificationSteps
    attr_accessor :personal_info, :residence_history, :employment_history, :education, :professional_license

    def initialize
      @personal_info = PersonalInfo.new
      @residence_history = ResidenceHistory.new
      @employment_history = EmploymentHistory.new
      @education = Education.new
      @professional_license = ProfessionalLicense.new
    end
  end

  # PersonalInfo structure
  class PersonalInfo
    attr_accessor :enabled, :modes

    def initialize
      @enabled = false
      @modes = Struct.new(:email, :phone, :full_name, :name_alias).new(false, false, false, false)
    end
  end

  # ResidenceHistory structure
  class ResidenceHistory
    attr_accessor :enabled, :years

    def initialize
      @enabled = false
      @years = 1
    end
  end

  # EmploymentHistory structure
  class EmploymentHistory
    attr_accessor :enabled, :mode, :modes

    def initialize
      @enabled = false
      @mode = 'years'
      @modes = Struct.new(:years, :employers).new(nil, nil)
    end
  end

  # Education structure
  class Education
    attr_accessor :enabled

    def initialize
      @enabled = false
    end
  end

  # ProfessionalLicense structure
  class ProfessionalLicense
    attr_accessor :enabled

    def initialize
      @enabled = false
    end
  end

  # ConsentsRequired structure
  class ConsentsRequired
    attr_accessor :driver_license, :drug_test, :biometric

    def initialize
      @driver_license = false
      @drug_test = false
      @biometric = false
    end

    def to_h
      {
        driver_license: @driver_license,
        drug_test: @drug_test,
        biometric: @biometric
      }
    end
  end

  # Signature structure
  class Signature
    attr_accessor :required, :mode

    def initialize
      @required = false
      @mode = 'none'
    end
  end

  # Get timeline years based on code
  def self.get_timeline_years(code)
    return 1 if code.nil? || code.length < 2

    case code[0]
    when 'R', 'E'
      case code[1]
      when '1' then 1
      when '3' then 3
      when '5' then 5
      else 1
      end
    else
      1
    end
  end

  # Get employer count based on code
  def self.get_employer_count(code)
    return 1 if code.nil? || code.length < 3 || code[0..1] != 'EN'

    case code[2]
    when '1' then 1
    when '2' then 2
    when '3' then 3
    else 1
    end
  end

  # Parse collection key into language and facets
  def self.parse_collection_key(key)
    raise ArgumentError, 'Invalid collection key: must be a string with at least 8 facets' unless key.is_a?(String)

    parts = key.split('-')
    raise ArgumentError, 'Invalid collection key: must have 8 facets separated by -' unless parts.length == 8

    language = parts[0]
    raise ArgumentError, 'Invalid language code: must be 2 characters' unless language.length == 2

    facets = parts[1..-1]

    # Validate residence code
    residence_code = facets[2]
    unless residence_code == 'N' || (residence_code.start_with?('R') && ['1', '3', '5'].include?(residence_code[1]))
      raise ArgumentError, 'Invalid residence code: must be N or R followed by 1, 3, or 5'
    end

    # Validate employment code
    employment_code = facets[3]
    unless employment_code == 'N' || 
           (employment_code.start_with?('E') && ['1', '3', '5'].include?(employment_code[1])) ||
           (employment_code.start_with?('EN') && ['1', '2', '3'].include?(employment_code[2]))
      raise ArgumentError, 'Invalid employment code: must be N, E followed by 1, 3, 5, or EN followed by 1, 2, 3'
    end

    # Validate education code
    education_code = facets[4]
    unless ['E', 'N'].include?(education_code)
      raise ArgumentError, 'Invalid education code: must be E or N'
    end

    # Validate professional license code
    professional_license_code = facets[5]
    unless ['P', 'N'].include?(professional_license_code)
      raise ArgumentError, 'Invalid professional license code: must be P or N'
    end

    { language: language, facets: facets }
  end

  # Get requirements based on collection key
  def self.get_requirements(key)
    parsed = parse_collection_key(key)
    requirements = Requirements.new
    
    # Set language
    requirements.language = parsed[:language]
    
    # Parse facets
    facets = parsed[:facets]
    
    # Personal Info (facets[0])
    personal_info_code = facets[0]
    if personal_info_code != 'N'
      requirements.verification_steps.personal_info.enabled = true
      
      # Parse personal info modes
      personal_info_code.each_char do |char|
        case char
        when 'E'
          requirements.verification_steps.personal_info.modes.email = true
        when 'P'
          requirements.verification_steps.personal_info.modes.phone = true
        when 'M'
          requirements.verification_steps.personal_info.modes.full_name = true
        when 'A'
          requirements.verification_steps.personal_info.modes.name_alias = true
        end
      end
      
      # Default to phone only if no valid modes found
      if !requirements.verification_steps.personal_info.modes.email &&
         !requirements.verification_steps.personal_info.modes.phone &&
         !requirements.verification_steps.personal_info.modes.full_name &&
         !requirements.verification_steps.personal_info.modes.name_alias
        requirements.verification_steps.personal_info.modes.phone = true
      end
    end
    
    # Residence History (facets[2])
    residence_code = facets[2]
    if residence_code != 'N'
      requirements.verification_steps.residence_history.enabled = true
      requirements.verification_steps.residence_history.years = get_timeline_years(residence_code)
    end
    
    # Employment History (facets[3])
    employment_code = facets[3]
    if employment_code != 'N'
      requirements.verification_steps.employment_history.enabled = true
      
      if employment_code.start_with?('EN')
        requirements.verification_steps.employment_history.mode = 'employers'
        requirements.verification_steps.employment_history.modes.employers = get_employer_count(employment_code)
      else
        requirements.verification_steps.employment_history.mode = 'years'
        requirements.verification_steps.employment_history.modes.years = get_timeline_years(employment_code)
      end
    end
    
    # Education (facets[4])
    education_code = facets[4]
    requirements.verification_steps.education.enabled = (education_code == 'E')
    
    # Professional License (facets[5])
    professional_license_code = facets[5]
    requirements.verification_steps.professional_license.enabled = (professional_license_code == 'P')
    
    # Consents (facets[1])
    consent_code = facets[1]
    if consent_code != 'N'
      # Parse individual consent types
      requirements.consents_required.driver_license = consent_code.include?('D')
      requirements.consents_required.drug_test = consent_code.include?('T')
      requirements.consents_required.biometric = consent_code.include?('B')
    end
    
    # Signature (facets[6])
    signature_code = facets[6]
    if signature_code != 'N'
      requirements.signature.required = true
      
      # Set signature mode based on code
      case signature_code
      when 'C'
        requirements.signature.mode = 'checkbox'
      when 'W'
        requirements.signature.mode = 'wet'
      else
        requirements.signature.mode = 'none'
      end
    end
    
    requirements
  end
end