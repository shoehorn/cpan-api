package MetaCPAN::Server::Controller::Root;
use Moose;
BEGIN { extends 'MetaCPAN::Server::Controller' }

__PACKAGE__->config( namespace => '' );

sub default : Path {
    my ( $self, $c ) = @_;
    $c->forward('/not_found');
}

sub not_found : Private {
    my ( $self, $c, @params ) = @_;
    my $message = join('/', @params);
    $c->clear_stash;
    $c->stash( { code => 404, message => $message || "Not found" } );
    $c->response->status(404);
    $c->forward($c->view('JSON'));
}

sub not_allowed : Private {
    my ( $self, $c, $message ) = @_;
    $c->clear_stash;
    $c->stash( { message => $message || 'Not allowed' } );
    $c->response->status(403);
    $c->forward($c->view('JSON'));
}

sub bad_request : Private {
    my ( $self, $c, $message, $code ) = @_;
    $c->clear_stash;
    $c->stash( { message => $message || 'Bad request' } );
    $c->response->status($code || 400);
    $c->forward($c->view('JSON'));
}

sub robots : Path("robots.txt") {
    my ( $self, $c ) = @_;
    $c->res->content_type("text/plain");
    $c->res->body("User-agent: *\nDisallow: /\n");
}

sub end : ActionClass('RenderView') {
    my ( $self, $c ) = @_;
    if (   $c->controller->does('MetaCPAN::Server::Role::JSONP')
        && $c->controller->enable_jsonp )
    {

        # See also: http://www.w3.org/TR/cors/
        if ( my $origin = $c->req->header('Origin') ) {
            $c->res->header( 'Access-Control-Allow-Origin' => $origin );
        }

        # call default view unless body has been set
        $c->forward( $c->view ) unless ( $c->res->body );
        $c->forward( $c->view('JSONP') );
        $c->res->content_type('text/javascript')
            if ( $c->req->params->{callback} );
    }

    unless(
        # Already have something set for fastly
        $c->res->header('Surrogate-Control')
        ) {
            # Make sure fastly doesn't cache anything by accident
            $c->res->header('Surrogate-Control' => 'no-store');
    }

}

1;
