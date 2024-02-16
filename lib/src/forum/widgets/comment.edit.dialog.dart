import 'package:fireship/fireship.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class CommentEditDialog extends StatefulWidget {
  const CommentEditDialog({
    super.key,
    this.post,
    this.parent,
    this.comment,
    this.showUploadDialog,
    this.focusOnTextField,
  });

  final PostModel? post;
  final CommentModel? parent;
  final CommentModel? comment;
  final bool? showUploadDialog;
  final bool? focusOnTextField;

  @override
  State<CommentEditDialog> createState() => _CommentEditDialogState();
}

class _CommentEditDialogState extends State<CommentEditDialog> {
  bool get isCreate => widget.comment == null;

  double? progress;

  CommentModel? _comment;
  CommentModel get comment => _comment!;

  final contentController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.comment != null) {
      // 수정
      _comment = widget.comment;
      contentController.text = comment.content;
    } else {
      _comment = CommentModel.fromPost(widget.post!);
    }

    if (widget.showUploadDialog == true) {
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        upload();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              autofocus: widget.focusOnTextField == true,
              controller: contentController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Comment',
              ),
              maxLines: 5,
              minLines: 3,
            ),
          ),

          /// 여기터 부터 코멘트 작성, 코멘트 사진 작성, 코멘트 좋아요, 신고, 차단

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(
                    onPressed: upload,
                    icon: const Icon(
                      Icons.camera_alt,
                      size: 32,
                    )),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    if (isCreate) {
                      await comment.create(
                        content: contentController.text,
                        category: widget.post!.category,
                        urls: comment.urls,
                        parent: widget.parent,
                      );
                      // TODO send push notification to post owner
                      // TODO send push notifications to other commenters
                      // Should it be here in Fireship
                      // or should it be a cloud function
                      dog("Post uid: ${widget.post?.uid}");
                      dog("Parent uid: ${widget.parent?.uid}");
                      dog("Comment uid: ${comment.uid}");
                      // TODO review and revise
                      // TODO DRY properly
                      if (widget.post?.uid != null) {
                        MessagingService.instance.sendTo(
                          uid: widget.post!.uid,
                          title: widget.post!.title,
                          body:
                              "${my?.displayName ?? "Someone"} commented on your post. ${comment.content}...",
                          extra: {
                            if (widget.post?.id != null)
                              "postId": widget.post?.id,
                            if (widget.parent?.id != null)
                              "parentId": widget.parent?.id,
                          },
                        );
                      }
                      if (widget.parent?.uid != null) {
                        MessagingService.instance.sendTo(
                          uid: widget.parent!.uid,
                          title: widget.post!.title,
                          body:
                              "${my?.displayName ?? "Someone"} replied on your comment. ${comment.content}...",
                          extra: {
                            if (widget.post?.id != null)
                              "postId": widget.post?.id,
                            if (widget.parent?.id != null)
                              "parentId": widget.parent?.id,
                          },
                        );
                      }
                    } else {
                      await comment.update(
                        content: contentController.text,
                        urls: comment.urls,
                      );
                    }

                    if (mounted) Navigator.of(context).pop(true);
                  },
                  child: Text(
                    isCreate ? '코멘트 작성' : '저장',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
              height: 16,
              child: Column(
                children: [
                  progress != null && progress!.isNaN == false
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: LinearProgressIndicator(
                            value: progress,
                          ),
                        )
                      : const SizedBox.shrink(),
                ],
              )),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: EditUploads(
              urls: comment.urls,
              onDelete: (url) => setState(
                () {
                  comment.urls.remove(url);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> upload() async {
    final String? url = await StorageService.instance.upload(
      context: context,
      progress: (p) => setState(() => progress = p),
      complete: () => setState(() => progress = null),
    );
    if (url != null) {
      setState(() {
        progress = null;
        comment.urls.add(url);
      });
    }
  }
}
