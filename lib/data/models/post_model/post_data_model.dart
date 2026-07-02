// lib/data/models/post_data_model.dart
import 'package:doctak_app/core/utils/app/AppData.dart';

// Note: This is just an interface to match the existing model structure
// You should use your actual model implementation here

class PostDataModel {
  Posts? posts;

  PostDataModel({this.posts});

  PostDataModel.fromJson(Map<String, dynamic> json) {
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
  List<Post>? data;
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
      data = <Post>[];
      json['data'].forEach((v) {
        data!.add(Post.fromJson(v));
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

class Post {
  int? id;
  String? userId;
  String? title;
  String? body;
  dynamic lat;
  dynamic lng;
  dynamic country;
  dynamic image;
  String? createdAt;
  String? updatedAt;
  String? backgroundColor;
  String? privacy;
  String? postType;
  Map<String, dynamic>? poll;
  dynamic tagging;
  int? views;
  double? relevanceScore;
  String? tags;
  String? displayTitle;
  String? displayBody;
  bool? highlightHashtagsInBody;
  String? organizationId;
  String? organizationSlug;
  String? accountType;
  String? authorName;
  String? authorAvatar;
  bool? authorVerified;
  bool? isBusinessPagePost;
  PostMeta? meta;
  List<Comments>? comments;
  Commenter? user;
  List<Media>? media;
  List<Likes>? likes;

  Post({
    this.id,
    this.userId,
    this.title,
    this.body,
    this.lat,
    this.lng,
    this.country,
    this.image,
    this.createdAt,
    this.updatedAt,
    this.backgroundColor,
    this.privacy,
    this.postType,
    this.poll,
    this.tagging,
    this.views,
    this.relevanceScore,
    this.tags,
    this.displayTitle,
    this.displayBody,
    this.highlightHashtagsInBody,
    this.organizationId,
    this.organizationSlug,
    this.accountType,
    this.authorName,
    this.authorAvatar,
    this.authorVerified,
    this.isBusinessPagePost,
    this.meta,
    this.comments,
    this.user,
    this.media,
    this.likes,
  });

  Post.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id']?.toString();
    title = json['title']?.toString();
    body = json['body']?.toString();
    lat = json['lat'];
    lng = json['lng'];
    country = json['country'];
    image = json['image'];
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    backgroundColor = json['background_color']?.toString();
    privacy = json['privacy']?.toString();
    postType = json['post_type']?.toString();
    if (json['poll'] is Map) {
      poll = Map<String, dynamic>.from(json['poll'] as Map);
    }
    tagging = json['tagging'];
    views = json['views'] is num ? (json['views'] as num).toInt() : int.tryParse('${json['views'] ?? ''}');
    relevanceScore = (json['relevance_score'] as num?)?.toDouble();
    tags = json['tags']?.toString();
    displayTitle = json['displayTitle']?.toString();
    displayBody = json['displayBody']?.toString();
    highlightHashtagsInBody = json['highlightHashtagsInBody'] == true
        ? true
        : json['highlightHashtagsInBody'] == false
            ? false
            : null;
    organizationId =
        json['organizationId']?.toString() ?? json['organization_id']?.toString();
    organizationSlug = json['organizationSlug']?.toString() ??
        json['organization_slug']?.toString();
    accountType =
        json['accountType']?.toString() ?? json['account_type']?.toString();
    authorName = json['authorName']?.toString();
    authorAvatar = json['authorAvatar']?.toString();
    authorVerified = json['authorVerified'] == true;
    isBusinessPagePost = json['isBusinessPagePost'] == true ||
        (organizationId != null && organizationId!.isNotEmpty);
    meta = json['meta'] != null ? PostMeta.fromJson(json['meta']) : null;
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
    data['body'] = body;
    data['lat'] = lat;
    data['lng'] = lng;
    data['country'] = country;
    data['image'] = image;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['background_color'] = backgroundColor;
    data['privacy'] = privacy;
    data['post_type'] = postType;
    if (poll != null) {
      data['poll'] = poll;
    }
    data['tagging'] = tagging;
    data['views'] = views;
    data['relevance_score'] = relevanceScore;
    if (meta != null) {
      data['meta'] = meta!.toJson();
    }
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

/// Deep-link metadata for a feed item, emitted by `GET /api/v1/posts`.
/// `deepLink` is a `doctak://post/<id>` URI; `webUrl` is the public https URL.
class PostMeta {
  String? type;
  String? deepLink;
  String? webUrl;
  String? ctaLabel;

  PostMeta({this.type, this.deepLink, this.webUrl, this.ctaLabel});

  PostMeta.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    deepLink = json['deepLink'];
    webUrl = json['webUrl'];
    ctaLabel = json['ctaLabel'];
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'deepLink': deepLink,
        'webUrl': webUrl,
        'ctaLabel': ctaLabel,
      };
}

class Comments {
  int? id;
  String? commenterId;
  String? commenterType;
  String? guestName;
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
  bool? isVerified;
  String? specialty;
  String? city;
  String? state;
  String? country;

  Commenter({this.id, this.name, this.profilePic, this.isVerified, this.specialty, this.city, this.state, this.country});

  Commenter.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    final rawName = (json['name'] ?? '').toString().trim();
    final firstLast = '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim();
    final username = (json['username'] ?? '').toString().trim();
    name = rawName.isNotEmpty ? rawName : (firstLast.isNotEmpty ? firstLast : (username.isNotEmpty ? username : 'Unknown'));
    profilePic = AppData.fullImageUrl(json['profile_pic']);
    isVerified = json['is_verified'] == true || json['is_verified'] == 1;
    specialty = (json['specialty'] ?? '').toString().trim().isEmpty ? null : json['specialty'].toString().trim();
    city = (json['city'] ?? '').toString().trim().isEmpty ? null : json['city'].toString().trim();
    state = (json['state'] ?? '').toString().trim().isEmpty ? null : json['state'].toString().trim();
    country = (json['country'] ?? '').toString().trim().isEmpty ? null : json['country'].toString().trim();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['profile_pic'] = profilePic;
    data['is_verified'] = isVerified;
    data['specialty'] = specialty;
    data['city'] = city;
    data['state'] = state;
    data['country'] = country;
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
    postId = json['post_id']?.toString();
    mediaType = json['media_type']?.toString() ?? json['mediaType']?.toString();
    mediaPath = json['media_path']?.toString() ??
        json['mediaPath']?.toString() ??
        json['url']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
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
