NAME := pmm
FILE := pmm.sh
PREFIX := /usr/local/bin

.PHONY: clean install uninstall

$(NAME): clean
	@test -f $(FILE) \
	&& cp $(FILE) $(NAME) \
	&& chmod 755 $(NAME)

clean:
	@$(RM) $(NAME)

install:
	@cp -i $(NAME) $(PREFIX)

uninstall:
	@$(RM) -i $(PREFIX)/$(NAME)
