require 'securerandom'

class ApplicationMailer # Does not inherit from ActionMailer
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TextHelper


  def mandrill_send(options)
    unsubscribe_token = generate_unsubscribe_token
    options[:unsubscribe_url] = unsubscribe_url(options[:participant_id],unsubscribe_token)
    options[:global_merge_vars] << { name: 'UNSUBSCRIBE_LINK',
                                     content: build_unsubscribe_link(options) }
    # TODO needs refactoring
    options[:global_merge_vars] << { name: 'UNSUBSCRIBE_URL',
                                    content: options[:unsubscribe_url] }
    message = {
      subject:      options[:subject],
      from_name:    "crowdAI",
      from_email:   "no-reply@crowdai.org",
      to: [
        {
          email:    options[:to],
          type:     "to"
        }
      ],
      global_merge_vars:  options[:global_merge_vars]
    }
    res = nil
    if !mailer_paused?
      res = MANDRILL.messages.send_template( options[:template], [], message) unless Rails.env.staging?
    end
    email_logger(options,unsubscribe_token)

    return [res, message]

    rescue Mandrill::UnknownTemplateError => e
      Rails.logger.debug("#{e.class}: #{e.message}")
      raise
  end


  def email_logger(options,unsubscribe_token)
    status = :sent
    status = :paused if mailer_paused?

    Email.create!(model_id: @model_id,
                  mailer: self.class.to_s,
                  recipients: options[:to],
                  options_json: options,
                  status: status,
                  participant_id: options[:participant_id],
                  email_preferences_token: unsubscribe_token,
                  token_expiration_dttm: DateTime.current + 7.days)
  end


  def mailer_paused?
    mailer = Mailer.where(mailer: self.class.to_s).first
    return mailer.paused
  end


  def unsubscribe_url(participant_id,unsubscribe_token)
    participant = Participant.find(participant_id)
    pref = participant.email_preferences.first
    url = "#{ENV['HOST']}/participants/#{participant.id}/email_preferences/#{pref.id}/edit?unsubscribe_token=#{unsubscribe_token}"
  end


  def generate_unsubscribe_token
    SecureRandom.urlsafe_base64(24)
  end


  def build_unsubscribe_link(options)
    "<div>" +
    "<a href='#{options[:unsubscribe_url]}'>Unsubscribe</a>" +
    "</div>"
  end


end
