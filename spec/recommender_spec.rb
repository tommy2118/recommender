require "recommender"

RSpec.describe Recommender do
  let(:users_ratings) {
    {
      angelica: {
        blues_traveler: 3.5,
        broken_bells: 2.0,
        norah_jones: 4.5,
        phoenix: 5.0,
        slightly_stoopid: 1.5,
        the_strokes: 2.5,
        vampire_weekend: 2.0
      },
      bill: {
        blues_traveler: 2.0,
        broken_bells: 3.5,
        deadmau5: 4.0,
        phoenix: 2.0,
        slightly_stoopid: 3.5,
        vampire_weekend: 3.0
      },
      chan: {
        blues_traveler: 5.0,
        broken_bells: 1.0,
        deadmau5: 1.0,
        norah_jones: 3.0,
        phoenix: 5,
        slightly_stoopid: 1.0
      },
      dan: {
        blues_traveler: 3.0,
        broken_bells: 4.0,
        deadmau5: 4.5,
        phoenix: 3.0,
        slightly_stoopid: 4.5,
        the_strokes: 4.0,
        vampire_weekend: 2.0
      },
      hailey: {
        broken_bells: 4.0,
        deadmau5: 1.0,
        norah_jones: 4.0,
        the_strokes: 4.0,
        vampire_weekend: 1.0
      },
      jordyn: {
        broken_bells: 4.5,
        deadmau5: 4.0,
        norah_jones: 5.0,
        phoenix: 5.0,
        slightly_stoopid: 4.5,
        the_strokes: 4.0,
        vampire_weekend: 4.0
      },
      sam: {
        blues_traveler: 5.0,
        broken_bells: 2.0,
        norah_jones: 3.0,
        phoenix: 5.0,
        slightly_stoopid: 4.0,
        the_strokes: 5.0
      },
      veronica: {
        blues_traveler: 3.0,
        norah_jones: 5.0,
        phoenix: 4.0,
        slightly_stoopid: 2.5,
        the_strokes: 3.0
      },
      tommy: {
        tears_for_fears: 4.0,
        eric_clapton: 4.0,
        run_d_mc: 2.0,
        foo_fighters: 5.0,
        marky_mark: 2.0
      },
    }
  }

  let(:user) { "Hailey" }
  let(:metric) { "Manhattan" }
  let(:recommender) { described_class.new(user, users_ratings, metric) }

  describe "#recommend" do
    let(:user) { "Hailey" }
    let(:metric) { "Pearson" }
    let(:expected) { {phoenix: 5.0, slightly_stoopid: 4.5} }
    it "returns a list of recommendations" do
      expect(recommender.recommend).to eq(expected)
    end
  end

  describe "#compute_nearest_neighbor" do
    let(:expected) { :veronica }

    it "returns the nearest neighbor of the user" do
      expect(recommender.compute_nearest_neighbor[1]).to eq(expected)
    end

    it "does not return the user being compared" do
      expect(recommender.compute_nearest_neighbor[1]).to_not eq(user)
    end

    it "nearest neighbor must be >= 0" do
      expect(recommender.compute_nearest_neighbor[1]).to_not eq(:tommy)
    end

    context "when metric is Manhattan" do
      it "calulates nearest neighbor distance as 2.0" do
        expect(recommender.compute_nearest_neighbor[0]).to eq(2)
      end
    end

    context "when metric is Euclidean" do
      let(:metric) { "Euclidean" }
      let(:recommender) { described_class.new(user, users_ratings, metric) }

      it "calulates nearest neighbor distance as 1.414" do
        expect(recommender.compute_nearest_neighbor[0]).to eq(1.414)
      end
    end

    context "when metric is Pearson" do
      let(:metric) { "Pearson" }
      let(:recommender) { described_class.new(user, users_ratings, metric) }

      it "calulates nearest neighbor distance as 0.6123724356957947" do
        expect(recommender.compute_nearest_neighbor[0]).to eq(0.6123724356957947)
      end
    end
  end

  describe "#minkowski_distance" do
    let(:hailey) { users_ratings[:hailey] }
    let(:tommy) { users_ratings[:tommy] }

    describe "when using manhattan distance" do
      let(:hailey) { users_ratings[:hailey] }
      let(:veronica) { users_ratings[:veronica] }
      let(:jordyn) { users_ratings[:jordyn] }
      let(:tommy) { users_ratings[:tommy] }
      let(:distance_between_hailey_and_veronica) { 2.0 }
      let(:distance_between_hailey_and_jordyn) { 7.5 }
      let(:distance_to_self) { 0 }

      it "returns the Manhattan distance between two users" do
        aggregate_failures do
          expect(recommender.minkowski_distance(hailey, veronica, 1))
            .to eq(distance_between_hailey_and_veronica)
          expect(recommender.minkowski_distance(hailey, jordyn, 1))
            .to eq(distance_between_hailey_and_jordyn)
          expect(recommender.minkowski_distance(hailey, hailey, 1))
            .to eq(distance_to_self)
        end
      end
    end

    describe "when using Euclidean distance" do
      let(:hailey) { users_ratings[:hailey] }
      let(:veronica) { users_ratings[:veronica] }
      let(:jordyn) { users_ratings[:jordyn] }
      let(:tommy) { users_ratings[:tommy] }
      let(:distance_between_hailey_and_veronica) { 1.414 }
      let(:distance_between_hailey_and_jordyn) { 4.387 }
      let(:distance_to_self) { 0 }

      it "returns the Manhattan distance between two users" do
        aggregate_failures do
          expect(recommender.minkowski_distance(hailey, veronica, 2))
            .to eq(distance_between_hailey_and_veronica)
          expect(recommender.minkowski_distance(hailey, jordyn, 2))
            .to eq(distance_between_hailey_and_jordyn)
          expect(recommender.minkowski_distance(hailey, hailey, 2))
            .to eq(distance_to_self)
        end
      end
    end

    it "returns -1 when there are no common ratings" do
      expect(recommender.minkowski_distance(hailey, tommy)).to eq(-1)
    end
  end

  describe "#pearson" do
    let(:angelica) { users_ratings[:angelica] }
    let(:bill) { users_ratings[:bill] }
    let(:hailey) { users_ratings[:hailey] }
    let(:jordyn) { users_ratings[:jordyn] }
    let(:angelica_and_bill_coefficient) { -0.90405349906826993 }
    let(:angelica_and_hailey_coefficient) { 0.42008402520840293 }
    let(:angelica_and_jordyn_coefficient) { 0.76397486054754316 }
    it "returns the Pearson Correlation Coefficient for two ratings" do
      aggregate_failures do
        expect(recommender.pearson(angelica, bill)).to eq(angelica_and_bill_coefficient)
        expect(recommender.pearson(angelica, hailey)).to eq(angelica_and_hailey_coefficient)
        expect(recommender.pearson(angelica, jordyn)).to eq(angelica_and_jordyn_coefficient)
      end
    end
  end

end
