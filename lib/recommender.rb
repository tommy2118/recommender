class Recommender

  attr_reader :users

  def initialize(username, users, metric)
    @username = username
    @users = users
    @metric = metric
  end

  def username
    @username.downcase.to_sym
  end

  def metric
    case @metric
    when "Manhattan"
      1
    when "Euclidean"
      2
    when "Pearson"
      3
    end
  end

  def recommend
    nearest = compute_nearest_neighbor[1]
    neighbor_ratings = users[nearest]
    user_ratings = users[username]
    neighbor_ratings.reject! { |k,_v| user_ratings.has_key?(k) }
    neighbor_ratings.sort_by { |_k,v| v }.reverse!.to_h
  end

  def compute_nearest_neighbor
    distances = []
    users.each_key do |user|
      unless user == username
        if metric == 3
          distance = pearson(users[user], users[username])
          distances << [distance, user]
        else
          distance = minkowski_distance(users[user], users[username], metric)
          distances << [distance, user]
        end
      end
    end

    if metric == 3
      return distances.sort.last
    end

    distances.reject! { |d| d[0] < 0 }
    distances.sort!
    distances.first
  end

  def minkowski_distance(rating_1, rating_2, p = metric)
    common_ratings = false
    distance = 0.0
    rating_1.each_key do |key|
      if rating_2.has_key?(key)
        distance += (rating_1[key] - rating_2[key]).abs ** p
        common_ratings = true
      end
    end

    if common_ratings
      (distance ** (1.0/p)).round(3)
    else
      -1
    end
  end

  def pearson(rating_1, rating_2)
    sum_xy = 0
    sum_x = 0
    sum_y = 0
    sum_x2 = 0
    sum_y2 = 0
    n = 0
    rating_1.each_key do |key|
      if rating_2.has_key?(key)
        n += 1
        x = rating_1[key]
        y = rating_2[key]
        sum_xy += x * y
        sum_x += x
        sum_y += y
        sum_x2 += x ** 2
        sum_y2 += y ** 2
      end
    end
    return 0 if n == 0

    denominator = Math.sqrt(sum_x2 - (sum_x ** 2) / n) * Math.sqrt(sum_y2 - (sum_y ** 2) / n)
    if denominator == 0
      0
    else
      (sum_xy - (sum_x * sum_y) / n) / denominator
    end
  end

end
