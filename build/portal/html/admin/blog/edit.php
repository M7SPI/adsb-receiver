<?php
    session_start();

    // Load the require PHP classes.
    require_once($_SERVER['DOCUMENT_ROOT'].DIRECTORY_SEPARATOR."classes".DIRECTORY_SEPARATOR."common.class.php");
    require_once($_SERVER['DOCUMENT_ROOT'].DIRECTORY_SEPARATOR."classes".DIRECTORY_SEPARATOR."account.class.php");
    require_once($_SERVER['DOCUMENT_ROOT'].DIRECTORY_SEPARATOR."classes".DIRECTORY_SEPARATOR."blog.class.php");

    $common = new common();
    $account = new account();
    $blog = new blog();

    // Check if the user is logged in.
    if (!$account->isAuthenticated()) {
        // The user is not logged in so forward them to the login page.
        header ("Location: login.php");
    }

    // Set updated variable to FALSE.
    $updated = FALSE;

    if ($common->postBack()) {
        // Update the contents of the blog post.
        $blog->editContentsByTitle($_POST['originalTitle'], $_POST['contents']);

        // Set updated to TRUE since settings were updated.
        $updated = TRUE;
    }

    // Get titles and dates for all blog posts.
    $post = $blog->getPostByTitle(urldecode($_GET['title']));


    // Properly format the date and convert to slected time zone.
    $date = new DateTime($post['date'], new DateTimeZone('UTC'));
    $date->setTimezone(new DateTimeZone($common->getSetting('timeZone')));
    $postDate = $date->format($common->getSetting('dateFormat'));

    ////////////////
    // BEGIN HTML

    require_once($_SERVER['DOCUMENT_ROOT'].DIRECTORY_SEPARATOR."admin".DIRECTORY_SEPARATOR."includes".DIRECTORY_SEPARATOR."header.inc.php");

    // Display the updated message if settings were updated.
    if ($updated) {
?>
        <div id="contents-saved" class="alert alert-success fade in" role="alert">
            <button type="button" class="close" data-dismiss="alert" aria-label="Close">
                <span aria-hidden="true">&times;</span>
            </button>
            Blog post contents have been updated.
        </div>
<?php
    }
?>
            <h1>Blog Management</h1>
            <hr />
            <h2>Edit Blog Post</h2>
            <h3><?php echo $post['title']; ?></h3>
            <p>Posted <strong><?php echo $postDate; ?></strong> by <strong><?php echo $common->getAdminstratorName($post['author']); ?></strong>.</p>
            <form id="edit-blog-post" method="post" action="edit.php?title=<?php echo urlencode($post['title']); ?>">
                <div class="form-group">
                    <textarea id="contents" name="contents"><?php echo $post['contents']; ?></textarea>
                </div>
                <input type="hidden" name="originalTitle" value="<?php echo $post['title']; ?>">
                <input type="submit" class="btn btn-default" value="Commit Changes">
            </form>
            <script src='https://cdn.ckeditor.com/ckeditor5/41.4.2/classic/ckeditor.js'></script>
            <script>
                ClassicEditor
                    .create( document.querySelector( '#contents' ) )
                    .catch( error => {
                        console.error( error );
                    } );
            </script>
            <style>
                .ck-editor__editable_inline {
                min-height: 350px;
            }
<?php
    require_once($_SERVER['DOCUMENT_ROOT'].DIRECTORY_SEPARATOR."admin".DIRECTORY_SEPARATOR."includes".DIRECTORY_SEPARATOR."footer.inc.php");
?>
