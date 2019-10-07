class ChangelogEntry < ApplicationRecord
  class EntryAlreadyPublishedError < StandardError; end;

  belongs_to :referenceable, polymorphic: true, optional: true
  belongs_to :created_by, class_name: "User"

  delegate :title, to: :referenceable, prefix: true
  delegate :icon, to: :referenceable
  delegate :name, :handle, to: :created_by, prefix: true

  scope :published, -> { where.not(published_at: nil) }

  def self.find_by_url_slug!(slug)
    id = slug.split("-").last

    find(id)
  end

  def referenceable_gid
    referenceable.to_global_id
  end

  def referenceable
    Referenceable.for(super)
  end

  def publish!(time = Time.current)
    raise EntryAlreadyPublishedError if published?

    update!(published_at: time)
  end

  def tweet!(tweet: default_tweet)
    referenceable.tweet(tweet)
  end

  def published?
    published_at.present?
  end

  def created_by?(user)
    created_by == user
  end

  def tweet_link_url
    case
    when details_html? then friendly_url
    when info_url? then info_url
    else ""
    end
  end

  def url_slug
    "#{title.parameterize}-#{id}"
  end

  private

  def friendly_url
    Rails.application.routes.url_helpers.changelog_entry_url(url_slug)
  end

  def default_tweet
    Tweet.from_entry(self)
  end
end
