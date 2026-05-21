# frozen_string_literal: true

require Rails.root.join(
          "plugins/discourse-solved-reminders-plugin/db/migrate/20260521063359_seed_existing_mark_solution_reminder_state",
        )

describe SeedExistingMarkSolutionReminderState do
  let(:reminder_sent_at_field) { "solved_reminder_last_sent_at" }

  before do
    @original_verbose = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = false
    set_site_setting.call("solved_enabled", "t")
    set_site_setting.call("solved_reminders_plugin_enabled", "t")
    allow(Migration::Helpers).to receive(:existing_site?).and_return(true)
  end

  after { ActiveRecord::Migration.verbose = @original_verbose }

  fab!(:author, :user)
  fab!(:reply_user, :user)

  # The migration reads site_settings directly, so these examples write the rows directly too.
  let(:set_site_setting) { lambda { |name, value| DB.exec(<<~SQL, name:, value:) } }
          INSERT INTO site_settings (name, data_type, value, created_at, updated_at)
          VALUES (:name, #{SiteSettings::TypeSupervisor.types[:bool]}, :value, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
          ON CONFLICT (name) DO UPDATE
             SET value = EXCLUDED.value,
                 updated_at = CURRENT_TIMESTAMP
        SQL

  let(:fabricate_topic) do
    lambda do |last_posted_at:|
      Fabricate(:topic_with_op, user: author).tap do |topic|
        topic.update!(last_post_user_id: reply_user.id, last_posted_at:, posts_count: 2)
      end
    end
  end

  it "seeds reminder state for currently eligible topics" do
    topic = fabricate_topic.call(last_posted_at: 15.days.ago)

    described_class.new.up

    expect(topic._custom_fields.exists?(name: reminder_sent_at_field)).to eq(true)
  end

  it "does not seed reminder state when the plugin is disabled" do
    set_site_setting.call("solved_reminders_plugin_enabled", "f")
    topic = fabricate_topic.call(last_posted_at: 15.days.ago)

    described_class.new.up

    expect(topic._custom_fields.exists?(name: reminder_sent_at_field)).to eq(false)
  end

  it "does not seed reminder state on fresh installs" do
    allow(Migration::Helpers).to receive(:existing_site?).and_return(false)
    topic = fabricate_topic.call(last_posted_at: 15.days.ago)

    described_class.new.up

    expect(topic._custom_fields.exists?(name: reminder_sent_at_field)).to eq(false)
  end

  it "does not seed reminder state for topics that are not eligible yet" do
    topic = fabricate_topic.call(last_posted_at: 13.days.ago)

    described_class.new.up

    expect(topic._custom_fields.exists?(name: reminder_sent_at_field)).to eq(false)
  end

  it "does not overwrite existing reminder state" do
    topic = fabricate_topic.call(last_posted_at: 15.days.ago)
    original_value = 30.days.ago.iso8601
    topic._custom_fields.create!(name: reminder_sent_at_field, value: original_value)

    described_class.new.up

    expect(topic._custom_fields.where(name: reminder_sent_at_field).pluck(:value)).to eq(
      [original_value],
    )
  end
end
