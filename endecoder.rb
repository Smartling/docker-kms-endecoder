#!/bin/env ruby

# Supported env variables
# INPUT_TEXT_BASE64 e.g. YT15Q1dJNGhKMW5oTCxyO1poTTlbTUl1Z2RxCmI9MjM0Cg==
#   Plain text input:
#     a="123"
#     b="354"
# ACTION e.g. "ENCRYPT" or "DECRYPT"
# AWS_KMS_KEY_ID e.g. 189d219f-0000-aaaa-bbbb-00000000
# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY_ID
# AWS_SECURITY_TOKEN
# AWS_ROLE_ARN

require 'rubygems'
require 'logger'
require 'aws-sdk-core'
require 'base64'

class KmsEndec
  def initialize(logger = nil)
    @logger = logger ||= Logger.new(STDOUT)
    begin
      kms = Aws::KMS::Client.new({:region => 'us-east-1'})
    rescue => e
      @logger.error "Failed to initialize KMS client."
    end
    @kms = kms
  end

  def encrypt(keyid, plaintext)
    begin
      resp = @kms.encrypt({
        :key_id => keyid,
        :plaintext => plaintext
      })
      return Base64.encode64(resp.ciphertext_blob)
    rescue => e
      @logger.error "Failed to encrypt provided text using key #{keyid}."
    end
  end

  def decrypt(ciphertext)
    begin
      resp = @kms.decrypt({
        :ciphertext_blob => ciphertext,
      })
      return resp.plaintext
    rescue => e
      @logger.error "Failed to decrypt provided text: #{e}"
      exit 1
    end
  end
end

class EnvParser
  ACTION_ENV_NAME = "ACTION"
  INPUT_ENV_NAME = "INPUT_TEXT_BASE64"
  KEY_ENV_NAME = "AWS_KMS_KEY_ID"

  DECRYPT_ACTION = "decrypt"
  ENCRYPT_ACTION = "encrypt"
  ALLOWED_ACTIONS = [ DECRYPT_ACTION, ENCRYPT_ACTION ]

  def initialize(logger = nil)
    @logger = logger ||= Logger.new(STDOUT)
    @parsed = {}
  end

  def parse_action
    raise "invalid #{ACTION_ENV_NAME}, valid: #{ALLOWED_ACTIONS.join(",")}" unless ALLOWED_ACTIONS.include?(ENV[ACTION_ENV_NAME])
  end

  def parse_input
    raise "#{INPUT_ENV_NAME} is missing" unless ENV[INPUT_ENV_NAME]
    # TODO: validate that input is in base64
  end

  def parse_key
    raise "#{KEY_ENV_NAME} is required for #{ENV[ACTION_ENV_NAME]} = #{ENCRYPT_ACTION}" if ENV[ACTION_ENV_NAME] == ENCRYPT_ACTION && !ENV[KEY_ENV_NAME]
    # TODO: add validation of key by regex
  end

  def parse_credentials
    # TODO:
    # AWS_SECRET_ACCESS_KEY_ID is provided without AWS_ACCESS_KEY_ID -- error
    # AWS_ACCESS_KEY_ID provided without AWS_SECRET_ACCESS_KEY_ID -- error
    # Validate AWS_SECRET_ACCESS_KEY_ID, AWS_ACCESS_KEY_ID, AWS_ROLE_ARN and AWS_SECURITY_TOKEN if provided
  end

  def parse
    begin
      parse_action
      parse_input
      parse_key
      parse_credentials
    rescue => e
      @logger.error "Failed to parse provided env variables: #{e.message}"
      return false
    end
    true
  end
end

Process.exit(1) unless EnvParser.new.parse
kms_endec_obj = KmsEndec.new

case ENV[EnvParser::ACTION_ENV_NAME]
  when EnvParser::ENCRYPT_ACTION
    puts kms_endec_obj.encrypt(ENV[EnvParser::KEY_ENV_NAME], ENV[EnvParser::INPUT_ENV_NAME])
  when EnvParser::DECRYPT_ACTION
    puts kms_endec_obj.decrypt(Base64.decode64(ENV[EnvParser::INPUT_ENV_NAME]))
end

Process.exit(0)
