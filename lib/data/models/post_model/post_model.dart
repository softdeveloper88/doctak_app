class PostModel {
  Posts? posts;

  PostModel({this.posts});

  PostModel.fromJson(Map<String, dynamic> json) {
    posts = json['posts'] != null ? Posts.fromJson(json['posts']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (posts != null) {
      data['posts'] = posts!.toJson();
    }
    return data;
  }
}

class Posts {
  int? currentPage;
  List<Data>? data;
  String? firstPageUrl;
  int? from;
  int? lastPage;
  String? lastPageUrl;
  List<Links>? links;
  String? nextPageUrl;
  String? path;
  int? perPage;
  dynamic prevPageUrl;
  int? to;
  int? total;

  Posts({this.currentPage, this.data, this.firstPageUrl, this.from, this.lastPage, this.lastPageUrl, this.links, this.nextPageUrl, this.path, this.perPage, this.prevPageUrl, this.to, this.total});

  Posts.fromJson(Map<String, dynamic> json) {
    currentPage = json['current_page'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
    firstPageUrl = json['first_page_url'];
    from = json['from'];
    lastPage = json['last_page'];
    lastPageUrl = json['last_page_url'];
    if (json['links'] != null) {
      links = <Links>[];
      json['links'].forEach((v) {
        links!.add(Links.fromJson(v));
      });
    }
    nextPageUrl = json['next_page_url'];
    path = json['path'];
    perPage = json['per_page'];
    prevPageUrl = json['prev_page_url'];
    to = json['to'];
    total = json['total'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['current_page'] = currentPage;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['first_page_url'] = firstPageUrl;
    data['from'] = from;
    data['last_page'] = lastPage;
    data['last_page_url'] = lastPageUrl;
    if (links != null) {
      data['links'] = links!.map((v) => v.toJson()).toList();
    }
    data['next_page_url'] = nextPageUrl;
    data['path'] = path;
    data['per_page'] = perPage;
    data['prev_page_url'] = prevPageUrl;
    data['to'] = to;
    data['total'] = total;
    return data;
  }
}

class Data {
  int? id;
  String? userId;
  String? title;
  dynamic lat;
  dynamic lng;
  dynamic country;
  dynamic image;
  String? createdAt;
  String? updatedAt;
  String? backgroundColor;
  int? relevanceScore;
  List<Comments>? comments;
  Commenter? user;
  List<Media>? media;
  List<Likes>? likes;

  Data({
    this.id,
    this.userId,
    this.title,
    this.lat,
    this.lng,
    this.country,
    this.image,
    this.createdAt,
    this.updatedAt,
    this.backgroundColor,
    this.relevanceScore,
    this.comments,
    this.user,
    this.media,
    this.likes,
  });

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    title = json['title'];
    lat = json['lat'];
    lng = json['lng'];
    country = json['country'];
    image = json['image'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    backgroundColor = json['background_color'];
    relevanceScore = json['relevance_score'];
    if (json['comments'] != null) {
      comments = <Comments>[];
      json['comments'].forEach((v) {
        comments!.add(Comments.fromJson(v));
      });
    }
    user = json['user'] != null ? Commenter.fromJson(json['user']) : null;
    if (json['media'] != null) {
      media = <Media>[];
      json['media'].forEach((v) {
        media!.add(Media.fromJson(v));
      });
    }
    if (json['likes'] != null) {
      likes = <Likes>[];
      json['likes'].forEach((v) {
        likes!.add(Likes.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['title'] = title;
    data['lat'] = lat;
    data['lng'] = lng;
    data['country'] = country;
    data['image'] = image;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['background_color'] = backgroundColor;
    data['relevance_score'] = relevanceScore;
    if (comments != null) {
      data['comments'] = comments!.map((v) => v.toJson()).toList();
    }
    if (user != null) {
      data['user'] = user!.toJson();
    }
    if (media != null) {
      data['media'] = media!.map((v) => v.toJson()).toList();
    }
    if (likes != null) {
      data['likes'] = likes!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Comments {
  int? id;
  String? commenterId;
  String? commenterType;
  dynamic guestName;
  dynamic guestEmail;
  String? commentableType;
  String? commentableId;
  String? comment;
  bool? approved;
  dynamic childId;
  dynamic deletedAt;
  String? createdAt;
  String? updatedAt;
  Commenter? commenter;

  Comments({
    this.id,
    this.commenterId,
    this.commenterType,
    this.guestName,
    this.guestEmail,
    this.commentableType,
    this.commentableId,
    this.comment,
    this.approved,
    this.childId,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
    this.commenter,
  });

  Comments.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    commenterId = json['commenter_id'];
    commenterType = json['commenter_type'];
    guestName = json['guest_name'];
    guestEmail = json['guest_email'];
    commentableType = json['commentable_type'];
    commentableId = json['commentable_id'];
    comment = json['comment'];
    approved = json['approved'];
    childId = json['child_id'];
    deletedAt = json['deleted_at'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    commenter = json['commenter'] != null ? Commenter.fromJson(json['commenter']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['commenter_id'] = commenterId;
    data['commenter_type'] = commenterType;
    data['guest_name'] = guestName;
    data['guest_email'] = guestEmail;
    data['commentable_type'] = commentableType;
    data['commentable_id'] = commentableId;
    data['comment'] = comment;
    data['approved'] = approved;
    data['child_id'] = childId;
    data['deleted_at'] = deletedAt;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (commenter != null) {
      data['commenter'] = commenter!.toJson();
    }
    return data;
  }
}

class Commenter {
  String? id;
  String? name;
  String? profilePic;

  Commenter({this.id, this.name, this.profilePic});

  Commenter.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    profilePic = json['profile_pic'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['profile_pic'] = profilePic;
    return data;
  }
}

class Media {
  int? id;
  String? postId;
  String? mediaType;
  String? mediaPath;
  String? createdAt;
  String? updatedAt;

  Media({this.id, this.postId, this.mediaType, this.mediaPath, this.createdAt, this.updatedAt});

  Media.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    postId = json['post_id'];
    mediaType = json['media_type'];
    mediaPath = json['media_path'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['post_id'] = postId;
    data['media_type'] = mediaType;
    data['media_path'] = mediaPath;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class Likes {
  int? id;
  String? userId;
  String? postId;
  String? createdAt;
  String? updatedAt;

  Likes({this.id, this.userId, this.postId, this.createdAt, this.updatedAt});

  Likes.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    postId = json['post_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['post_id'] = postId;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class Links {
  String? url;
  String? label;
  bool? active;

  Links({this.url, this.label, this.active});

  Links.fromJson(Map<String, dynamic> json) {
    url = json['url'];
    label = json['label'];
    active = json['active'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['url'] = url;
    data['label'] = label;
    data['active'] = active;
    return data;
  }
}
