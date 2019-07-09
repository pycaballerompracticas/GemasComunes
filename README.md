# Implementación de gemas comuners en Rails


Primero debemos instalar rails en nuestro terminal
```
gem install rails
```

Luego se crea un nuevo proyecto , en este caso usaremos SQLite como motor de base de datos. Para esto debemos correr el siguiente comando en la terminal.
```
rails new practica
```
Editamos el archivo <code>Gemfile</code> para agregar las gemas que usaremos para esta practica, las cuales son <code>Carrierwave</code> para la subida de archivos , <code>will_paginate</code> para la paginacion, <code>wicked_pdf</code> para la generacion de archivos pdf
```
gem 'carrierwave'
gem 'will_paginate'
gem 'will_paginate-bootstrap'
gem 'wicked_pdf'
gem 'wkhtmltopdf-binary'
gem 'wkhtmltopdf-binary-edge' 
```
Instalar las nuevas gemas agregadas al <code>Gemfile</code> corriendo el siguiente comando en la terminal.
```
bundle install
```
Crearemos una entidad Post para realizar las pruebas, para ello corremos el siguiente comando en la terminar

```
rails g scaffold Post title:string body:text image:string
```

Ejecutamos el siguiente comando en la terminal para realizar la migración y crear el modelo User en base de datos.
```
rails db:migrate
```

Luego de esto modificamos el archivo <code>config/routes.rb</code>
```
resources :posts
root to: 'posts#index'
```
modificamos el archivo posts_controller.rb
```
class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update]
 
  def index
    @posts = Post.order('created_at DESC')
  end
 
  def show
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
```
Luego pasamos a la construccion de la vista index, para ello modificamos el archivo <code>views/posts/index.html.erb</code> y colocamos lo siguiente:
```
<h1>Posts</h1>
<%= link_to 'Add post', new_post_path %> 
<%= render @posts %>
```

Y en caso de que no exista creamos el siguiente archivo <code>views/posts/_post.html.erb</code> y colocamos lo siguiente:
```
<h2><%= link_to post.title, post_path(post) %></h2>
 
<p><%= truncate(post.body, length: 150) %></p>
 
<p><%= link_to 'Edit', edit_post_path(post) %></p>
<hr>
```
en la parte anterior se uso el truncate para mostrar solo los primeros 150 caracteres de la publicacion

## Integrando Carrierwave

Como ya incluímos la gema, carrierwave almacena la configuracion dentro de los uploaders que se incluyen en los modelos, entonces para generar un uploader usamos el siguiente comando
```
rails generate uploader Image
```
Ahora dentro de app/uploaders, se encontrara un nuevo archivo llamado image_uploader.rb

Luego debemos incluir el uploader al modelo <code>models/post.rb</code> agregando la siguiente linea:
```
mount_uploader :image, ImageUploader
```
**Usando Almacenamiento local**

El uploader ya tiene algunos ajustes por defecto, pero almenos necesitamos saber en donde vamos a almacenar los archivos subidos, esto lo modificaremos en el archivo <code>uploaders/image_uploader.rb</code> 
```
 storage :file
  # storage :fog

```
para este caso los archivos subidos seran colocados en la carpeta public/uploads

**Usando S3** 

Para esto primero debemos colocar e instalar la siguiente gema en el gemfile
```
gem "fog-aws"
```
Luego de esto en la consola escribimos el comando <code>bundle install</code>

Para esta configuracion debemos de tener un bucket creado en AWS S3, ya que necesitaremos uno creado, por lo cual se debe de crear una cuenta en [AWS](https://aws.amazon.com/es/s3/),en la seccion de referencias se puede encontrar un video para la creacion de esta. 

A continuacion crearemos el inicializador para Carrierwave y configuremos el almacenamiento en la nube de manera global <code>config/initializers/carrierwave.rb</code>

```
CarrierWave.configure do |config|
  config.fog_provider = 'fog/aws'
  config.fog_credentials = {
      provider:              'AWS',
      aws_access_key_id:     ENV['S3_KEY'],  #Reemplazar por los datos correspondientes o modificar las variables de entorno
      aws_secret_access_key: ENV['S3_SECRET'],
      region:                ENV['S3_REGION'],
  }
  config.fog_directory  = ENV['S3_BUCKET']
end
```
Se nos solicitara los datos dados de la cuenta de AWS, como Access key ID, secret access key, el nombre del bucket y la region aunque esta es opcional.

Luego en el uploader seleccionaremos para almacenar los archivos en la nube, esto lo modificaremos en el archivo <code>uploaders/image_uploader.rb</code>
```
 #storage :file
 storage :fog
```

**Continuando con la implementacion**

Aca vamos a crear y una nueva vista y un formulario para poder comenzar a subir archivos, esto lo realizamos en el archivo <code>views/posts/new.html.erb</code> 
```
<h1>New post</h1>
 
<%= render 'form', post: @post %>
```
y el formulario en <code>views/posts/_form.html.erb</code> en caso de no existir creamos el archivo
```
<%= form_for post do |f| %>
  <div>
    <%= f.label :title  %>
    <%= f.text_field :title ,size: "49"%>
  </div>
 <br>
  <div>
    <%= f.label :body %>
    <%= f.text_area :body, size: '50x5' %>
  </div>
 <br>
  <div>
    <%= f.label :image %>
    <%= f.file_field :image %>
  </div>
 <br>
  <%= f.submit %>
<% end %>
```
 Finalmente creamos la vista para editar y para mostrar

 Iniciamos con el de edit <code>views/posts/edit.html.erb</code>
```
<h1>Editing Post</h1>
 
<%= render 'form', post: @post %>
```
luego modificamos la vista show en el cual observamos la imagen subida anteriormente <code>views/posts/show.html.erb</code>

```
<p id="notice"><%= notice %></p>

<p>
  <strong>Title:</strong>
  <%= @post.title %>
</p>

<p>
  <strong>Body:</strong>
  <%= @post.body %>
</p>

<p>
  <strong>Image:</strong>
  <%= image_tag(@post.image.url, alt: 'Image',style: "height: 50%; width: 50%") if @post.image? %> 
<br>
<br>
<%= link_to 'Edit', edit_post_path(@post) %> |
<%= link_to 'Back', posts_path %>
```
## Integrando Will_paginate

Como anteriormente instalamos la gema , ahora debemos modificar el index en el controlador <code>posts_controller.rb</code>
```
def index
    @posts = Post.all.paginate(page: params[:page], per_page: 3).order('created_at DESC')
  end
```
en donde en el comando <code>per_page:</code> podemos seleccionar el numero maximo de elementos a mostrar por pagina, y la seccion de order es para mostrarlo en orden descendente.

Luego agregamos lo siguiente a la vista index para controlar la pagina actual.
```
<%= will_paginate @posts %>
```
Con esto realizamos la paginacion correctamente.

## Integrando Wicked PDF

Ya que hemos agregado las gemas necesarias debemos de crear el inicializador con el siguiente comando
```
rails generate wicked_pdf
```
y luego agregar lo siguiente al archivo <code>config/initializers/mime_types.rb</code>
```
Mime::Type.register "application/pdf", :pdf
```

En caso de tener un error con la gema wkhtmltopdf  **"Location of wkhtmltopdf unknown"**
se debe de instalar _wkhtmltopdf_ en el computador y modificar el siguiente archivo <code>config/initializers/wicked_pdf.rb</code>
```
WickedPdf.config = {
   exe_path: 'C://Program Files/wkhtmltopdf/bin/wkhtmltopdf.exe',
}
```

Luego de esto modificamos en controlador <code>posts_controller.rb</code> en el endpoint show , para que este permita formato pdf
```
def show
    @post = Post.find(params[:id])
  respond_to do |format|
      format.html
      format.pdf{render pdf: "pdf_name"}   # Excluding ".pdf" extension.
    end
  end
```
Luego de esto creamos el archivo <code>views/posts/show.pdf.erb</code> y agregamos la siguiente plantilla html
```
<!DOCTYPE html>
<html>
<head>
<link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap.min.css" integrity="sha384-HSMxcRTRxnN+Bdg0JdbxYKrThecOKuH5zCYotlSAcp1+c8xmyTe9GYg1l9a69psu" crossorigin="anonymous">
</head>
<body>
	
			
</body>
</html>

```
ya dentro de este archivo dentro del campo <code>body</code> agregaremos los campos que vamos a mostrar
```
<h2>Titulo Post</h2>
<h2><%= @post.title %></h2>
<br>
<h2>Contenido</h2>
<h4><%= truncate(@post.body, length: 9999) %></h4>
<br> 
<h2>Imagen</h2>
<%= wicked_pdf_image_tag("#{@post.image}") %>
```
En donde hacemos uso de el helper <code><%= wicked_pdf_image_tag("#{@post.image}") %></code> para poder agregar la imagen al documento pdf y en la seccion <code>"#{@post.image}"</code> es la ruta en donde se encuentra la imagen

Luego necesitamos de un enlace en la vista que nos permita visualizar el pdf, para ello agregamos lo siguiente a la vista <code>views/posts/_post.html.erb</code>
```
<p><%= link_to 'Download PDF', post_path(post, format: :pdf) %></p>
```
en el cual le decimos que nos muestre esa vista del post en formato pdf.

Finalmente ejecutamos el servidor con el comando 
```
rails s
```
Y verificamos que funcione correctamente.

## Referencias
* [Subiendo Con Rails y Carrierwave](https://code.tutsplus.com/es/articles/uploading-with-rails-and-carrierwave--cms-28409)
* [Will_paginate](https://github.com/mislav/will_paginate)
* [Wicked PDF](https://github.com/mileszs/wicked_pdf)
* [Configure Carrierwave for AWS S3 Storage with Heroku](https://www.youtube.com/watch?v=afByHGIWKYQ) (Video)
