FROM ubuntu:latest

LABEL maintainer="ThisWaySir@github.com"

ENV TZ Asia/Shanghai

RUN apt-get update \
        && apt-get install -y sudo wget curl git ncurses-dev build-essential bzip2 openssh-server python3 python3-pip privoxy golang-1.9 clang cmake zsh \
        && pip3 install shadowsocks

# ssh server
#sed -ri 's/^session\s+required\s+pam_loginuid.so$/session optional pam_loginuid.so/' /etc/pam.d/sshd
# set PermitRootLogin yes
RUN sed -i 's/PermitRootLogin\s.*/PermitRootLogin yes/g' /etc/ssh/sshd_config \
    && service ssh restart

RUN adduser --disabled-password --gecos '' karel \
        && adduser karel sudo \
        && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER karel

WORKDIR /home/karel

# proxy
RUN echo '{"server":"X.X.X.X", "server_port":X, "local_address": "127.0.0.1", "local_port":1080, "password":"XXXX", "timeout":300, "method":"aes-256-cfb", "fast_open": false}' >> $HOME/.shadowsocks.json \
        && cp /etc/privoxy/config $HOME/.privoxy \
        && echo 'forward-socks5    /   127.0.0.1:1080 .' >> $HOME/.privoxy \
        && (nohup /usr/local/bin/sslocal -c $HOME/.shadowsocks.json &) \
        && (nohup /usr/sbin/privoxy $HOME/.privoxy &) \
        && echo "export http_proxy='127.0.0.1:8118'" >> $HOME/.zshrc \
        && echo "export https_proxy='127.0.0.1:8118'" >> $HOME/.zshrc \
        && echo "export no_proxy='XXXX.com'" >> $HOME/.zshrc

# golang
RUN export GOROOT=/usr/lib/go-1.9 \
        && mkdir -p $HOME/code/go \
        && export GOPATH=$HOME/code/go \
        && export PATH=$PATH:$GOROOT/bin:$GOPATH/bin \
        && go get -u github.com/golang/dep/cmd/dep \
        && go install github.com/golang/dep

# port
EXPOSE 22 443 80 9999

# vim 8.0
# ref https://github.com/Valloric/YouCompleteMe/wiki/Building-Vim-from-source
RUN wget ftp://ftp.home.vim.org/pub/vim/unix/vim-8.0.tar.bz2 \
        && bzip2 -d vim-8.0.tar.bz2 \
        && tar xf vim-8.0.tar \
        && cd vim80/ \
#RUN wget https://github.com/vim/vim/archive/master.zip \
#    && unzip master.zip \
#    && cd vim-master/src \
        && ./configure --enable-python3interp=yes --with-python3-config-dir=/usr/lib/python3.5/config-3.5m-x86_64-linux-gnu \
        && make \
        && sudo make install \
        && cd .. \
        && rm -rf vim80 \
        && rm vim-8.0.tar
#USER karel

# ycm
RUN git clone --depth 1  https://github.com/Valloric/YouCompleteMe $HOME/.vim/bundle/YouCompleteMe \
        && cd $HOME/.vim/bundle/YouCompleteMe \
        && git submodule update --init --recursive \
        && python3 install.py --clang-completer

RUN cp $HOME/.vim/bundle/YouCompleteMe/third_party/ycmd/examples/.ycm_extra_conf.py $HOME/.vim/ \
        && cd $HOME/.vim/bundle/YouCompleteMe  && cp -r autoload plugin third_party python $HOME/.vim

RUN echo "let g:ycm_server_python_interpreter='/usr/bin/python3.5'" >> $HOME/.vimrc \
        && echo "let g:ycm_global_ycm_extra_conf='$HOME/.vim/.ycm_extra_conf.py'" >> $HOME/.vimrc \
        && echo "let g:ycm_seed_identifiers_with_syntax=1" >> $HOME/.vimrc \
        && echo "set completeopt-=preview" >> $HOME/.vimrc \
		&& echo "set encoding=utf-8" >> $HOME/.vimrc \
		&& echo "set backspace=indent,eol,start" >> $HOME/.vimrc

RUN wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O - | zsh || true \
        && sudo chsh -s /bin/zsh

RUN echo "karel:XXXX" | sudo chpasswd
#        && sudo sed -i 's/.*ALL=(ALL) NOPASSWD:ALL//g' /etc/sudoers

RUN git clone https://github.com/VundleVim/Vundle.vim.git $HOME/.vim/bundle/Vundle.vim \
        && git clone https://github.com/ThisWaySir/dev-env.git $HOME \
        && mv $HOME/dev-env/vimrc $HOME/.vimrc \
        && rm -rf $HOME/dev-env

# install tmux powerline, etc...
# set ENV and sshd config, then start proxy, tang-dang!
