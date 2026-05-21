# frozen_string_literal: true

describe Jobs::MarkAsSolution do
  let(:reminder_sent_at_field) { SolvedReminders::MARK_AS_SOLUTION_REMINDER_SENT_AT_FIELD }

  it "runs daily so shorter reminder windows are honored" do
    expect(described_class.every).to eq(1.day)
  end

  before do
    SiteSetting.solved_enabled = true
    SiteSetting.allow_solved_on_all_topics = true
    SiteSetting.solved_reminders_plugin_enabled = true
    SiteSetting.remind_mark_solution_repeat_after_days = 14
  end

  describe "#execute" do
    fab!(:user)
    fab!(:topic) do
      Fabricate(:topic_with_op, last_post_user_id: user.id, last_posted_at: 170.days.ago)
    end
    fab!(:post) { Fabricate(:post, topic: topic, user: user, post_number: 2) }

    context "when the topic is not solved" do
      it "should send the PM to user to mark a post as solution" do
        expect { described_class.new.execute({}) }.to change {
          Topic.where(archetype: Archetype.private_message).count
        }.by(1)
        expect(Topic.last.title).to eq(I18n.t("mark_as_solution.title"))
      end

      it "records that the topic has been reminded" do
        described_class.new.execute({})

        expect(topic.reload.custom_fields[reminder_sent_at_field]).to be_present
      end
    end

    context "when the reminder threshold is shorter than the job's original cadence" do
      before { SiteSetting.remind_mark_solution_after_days = 2 }

      it "sends a PM once the topic crosses the threshold" do
        topic.update!(last_posted_at: 3.days.ago)

        expect { described_class.new.execute({}) }.to change {
          Topic.where(archetype: Archetype.private_message).count
        }.by(1)
      end

      it "does not send a PM before the topic crosses the threshold" do
        topic.update!(last_posted_at: 1.day.ago)

        expect { described_class.new.execute({}) }.to not_change {
          Topic.where(archetype: Archetype.private_message).count
        }
      end
    end

    context "when the topic has already been reminded" do
      it "does not immediately send another PM for the same topic" do
        described_class.new.execute({})

        expect { described_class.new.execute({}) }.to not_change {
          Topic.where(archetype: Archetype.private_message).count
        }
      end

      it "sends another PM after the repeat interval" do
        described_class.new.execute({})
        topic
          ._custom_fields
          .find_by!(name: reminder_sent_at_field)
          .update!(
            value: (SiteSetting.remind_mark_solution_repeat_after_days.days.ago - 1.day).iso8601,
          )

        expect { described_class.new.execute({}) }.to change {
          Topic.where(archetype: Archetype.private_message).count
        }.by(1)
      end

      it "uses the repeat interval site setting" do
        SiteSetting.remind_mark_solution_repeat_after_days = 3
        described_class.new.execute({})

        topic
          ._custom_fields
          .find_by!(name: reminder_sent_at_field)
          .update!(value: 2.days.ago.iso8601)

        expect { described_class.new.execute({}) }.to not_change {
          Topic.where(archetype: Archetype.private_message).count
        }

        topic
          ._custom_fields
          .find_by!(name: reminder_sent_at_field)
          .update!(value: 4.days.ago.iso8601)

        expect { described_class.new.execute({}) }.to change {
          Topic.where(archetype: Archetype.private_message).count
        }.by(1)
      end

      it "refreshes the reminder timestamp after sending another PM" do
        described_class.new.execute({})
        topic
          ._custom_fields
          .find_by!(name: reminder_sent_at_field)
          .update!(
            value: (SiteSetting.remind_mark_solution_repeat_after_days.days.ago - 1.day).iso8601,
          )

        described_class.new.execute({})

        expect { described_class.new.execute({}) }.to not_change {
          Topic.where(archetype: Archetype.private_message).count
        }
      end
    end

    context "when the topic is solved" do
      before { DiscourseSolved.accept_answer!(post, Discourse.system_user) }

      it "should not send the PM to user" do
        expect { described_class.new.execute({}) }.to not_change {
          Topic.where(archetype: Archetype.private_message).count
        }
      end
    end

    context "when the plugin is disabled" do
      it "should not send the PM to user" do
        SiteSetting.solved_reminders_plugin_enabled = false
        expect { described_class.new.execute({}) }.to not_change {
          Topic.where(archetype: Archetype.private_message).count
        }
      end
    end
  end
end
