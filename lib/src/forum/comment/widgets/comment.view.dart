import 'package:fireship/fireship.dart';
import 'package:fireship/src/forum/comment/widgets/comment.content.dart';
import 'package:flutter/material.dart';

class CommentView extends StatefulWidget {
  const CommentView({
    super.key,
    required this.post,
    required this.comment,
    this.onCreate,
  });

  final PostModel post;
  final CommentModel comment;
  final Function? onCreate;

  @override
  State<CommentView> createState() => _CommentViewState();
}

class _CommentViewState extends State<CommentView> {
  int? previousNoOfLikes;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: widget.comment.leftMargin),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        UserAvatar(
          uid: widget.comment.uid,
          onTap: () => UserService.instance.showPublicProfile(
            context: context,
            uid: widget.comment.uid,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommentContent(comment: widget.comment),
              const SizedBox(height: 8),
              DisplayDatabasePhotos(
                path:
                    '${Path.comment(widget.post.id, widget.comment.id)}/${Field.urls}',
              ),
              Theme(
                data: Theme.of(context).copyWith(
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      visualDensity: const VisualDensity(
                        horizontal: -2,
                        vertical: 0,
                      ),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () async {
                        final re =
                            await ForumService.instance.showCommentCreateScreen(
                          context,
                          post: widget.post,
                          parent: widget.comment,
                          // focusOnTextField: true,
                        );
                        if (re == true) {
                          widget.onCreate?.call();
                        }
                      },
                      child: const Text('답글'),
                    ),
                    TextButton(
                      onPressed: widget.comment.like,
                      child: Value(
                        path: widget.comment.ref.child(Field.likes).path,
                        builder: (likes) {
                          previousNoOfLikes = (likes as Map? ?? {}).keys.length;
                          return Text('좋아요${likeText(previousNoOfLikes)}');
                        },
                        onLoading: Text('좋아요${likeText(previousNoOfLikes)}'),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ChatService.instance.showChatRoom(
                            context: context, uid: widget.comment.uid);
                      },
                      child: const Text('채팅'),
                    ),
                    const Spacer(),
                    PopupMenuButton(itemBuilder: (context) {
                      return [
                        const PopupMenuItem(
                          value: 'block',
                          child: Text('차단'),
                        ),
                        const PopupMenuItem(
                          value: 'report',
                          child: Text('신고'),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('수정'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('삭제'),
                        ),
                      ];
                    }, onSelected: (value) async {
                      if (value == 'report') {
                        final re = await input(
                          context: context,
                          title: T.reportInputTitle.tr,
                          subtitle: T.reportInputMessage.tr,
                          hintText: T.reportInputHint.tr,
                        );
                        if (re == null || re == '') return;
                        await ReportService.instance.report(
                          commentId: widget.comment.id,
                          reason: re,
                        );
                        if (context.mounted) {
                          toast(context: context, message: '신고가 접수되었습니다.');
                        }
                      } else if (value == 'block') {
                        bool? re = await confirm(
                          context: context,
                          title: my!.hasBlocked(widget.comment.uid)
                              ? T.unblock.tr
                              : T.block.tr,
                          message: my!.hasBlocked(widget.comment.uid)
                              ? T.unblockConfirmMessage
                              : T.blockConfirmMessage.tr,
                        );
                        if (re != true) return;
                        re = await my?.block(widget.comment.uid);
                        if (context.mounted) {
                          toast(
                            context: context,
                            title: re == true ? T.blocked.tr : T.unblocked.tr,
                            message: re == true
                                ? T.blockedMessage.tr
                                : T.unblockedMessage.tr,
                          );
                        }
                      } else if (value == 'edit') {
                        await ForumService.instance.showCommentUpdateScreen(
                            context,
                            comment: widget.comment);
                        widget.post.reload();
                      } else if (value == 'delete') {
                        final re = await confirm(
                          context: context,
                          title: T.deleteCommentConfirmTitle.tr,
                          message: T.deleteCommentConfirmMessage.tr,
                        );
                        if (re != true) return;
                        await widget.comment.delete();
                      }
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
