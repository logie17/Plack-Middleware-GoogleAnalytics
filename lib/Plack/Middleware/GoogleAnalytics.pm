package Plack::Middleware::GoogleAnalytics; 
use strict;
use warnings;
use parent qw( Plack::Middleware );
use Plack::Util;
use Plack::Util::Accessor qw(ga_id);
use Text::MicroTemplate qw(:all);

sub ga_template {<<'EOF'};
<script type="text/javascript">

  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', '<?= $_[0] ?>']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();

</script>
EOF
 
sub call {
    my ($self, $env) = @_;

    my $res = $self->app->($env);

    $self->response_cb($res, sub {
        my $res             = shift;
        my $header          = Plack::Util::headers($res->[1]);
        my $content_type    = $header->get('Content-Type');
        my $ga_id           = $self->ga_id;

        return unless defined $content_type and $content_type =~ qr[text/html] and $ga_id;

        my $body = [];
        Plack::Util::foreach($res->[2], sub { push @$body, $_[0]; });
        $body = join '', @$body;
        $body .= render_mt($self->ga_template, $ga_id)->as_string;

        $res->[2] = [$body];
        $header->set('Content-Length', length $body);

        return;
    });
}

1;
