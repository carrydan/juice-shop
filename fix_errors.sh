#!/bin/bash

# Убедитесь, что находитесь в корне проекта
# Применение изменений для импорта и инициализации socket.io Server
echo "Исправление импорта и инициализации socket.io Server..."
find . -name '*.ts' -exec sed -i 's/import { Server } from '\''socket.io'\'';/import { Server as IOServer } from '\''socket.io'\'';/g' {} \;
find . -name '*.ts' -exec sed -i 's/const io: Server = new Server();/const io: IOServer = new IOServer();/g' {} \;

# Исправление типа BasketItem в models/relations.ts
echo "Исправление типа BasketItem в models/relations.ts..."
find ./models/relations.ts -exec sed -i 's/typeof BasketItem/BasketItem/g' {} \;

# Добавление свойства bid в нужные файлы
echo "Добавление свойства 'bid'..."
find ./routes/*.ts -exec sed -i 's/{ data: User; status: string; }/{ data: User; status: string; bid: number; }/g' {} \;

# Исправление проблемы с rawBody в server.ts
echo "Исправление rawBody в server.ts..."
find ./server.ts -exec sed -i 's/req.rawBody/(req as CustomRequest).rawBody/g' {} \;

# Установка пакета form-data и замена метода getHeaders
echo "Установка form-data и замена метода getHeaders..."
npm install form-data
find ./test/api/*.ts -exec sed -i 's/formData.getHeaders()/form.getHeaders()/g' {} \;

echo "Все исправления внесены!"
