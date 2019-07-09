class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update]
 
  def index
    @posts = Post.all.paginate(page: params[:page], per_page: 3).order('created_at DESC')
  end
 
  def show
    @post = Post.find(params[:id])
  respond_to do |format|
      format.html
      format.pdf{render pdf: "pdf_name"}   # Excluding ".pdf" extension.
    end
  end
 
  def new
    @post = Post.new
  end
 
  def create
    @post = Post.new(post_params)
    if @post.save
      redirect_to posts_path
    else
      render :new
    end
  end
 
  def edit
  end
 
  def update
    if @post.update_attributes(post_params)
      redirect_to post_path(@post)
    else
      render :edit
    end
  end
 
  private
 
  def post_params
    params.require(:post).permit(:title, :body, :image)
  end
 
  def set_post
    @post = Post.find(params[:id])
  end
end