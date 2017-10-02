///////////////////////////////////////////////////////////////////////////////
// 
// Служебный модуль с реализацией сценариев обработки файлов КорректировкаОписанияФорм
//
///////////////////////////////////////////////////////////////////////////////

// ИмяСценария
//	Возвращает имя сценария обработки файлов
//
// Возвращаемое значение:
//   Строка   - Имя текущего сценария обработки файлов
//
Функция ИмяСценария() Экспорт
	
	Возврат "КорректировкаОписанияФорм";

КонецФункции // ИмяСценария()

// ОбработатьФайл
//	Выполняет обработку файла
//
// Параметры:
//  АнализируемыйФайл		- Файл - Файл из журнала git для анализа
//  КаталогИсходныхФайлов  	- Строка - Каталог расположения исходных файлов относительно каталог репозитория
//  ДополнительныеПараметры - Структура - Набор дополнительных параметров, которые можно использовать 
//  	* Лог  					- Объект - Текущий лог
//  	* ИзмененныеКаталоги	- Массив - Каталоги, которые необходимо добавить в индекс
//		* КаталогРепозитория	- Строка - Адрес каталога репозитория
//		* ФайлыДляПостОбработки	- Массив - Файлы, изменившиеся / образоавшиеся в результате работы сценария
//											и которые необходимо дообработать
//
// Возвращаемое значение:
//   Булево   - Признак выполненной обработки файла
//
Функция ОбработатьФайл(АнализируемыйФайл, КаталогИсходныхФайлов, ДополнительныеПараметры) Экспорт
	
	Лог = ДополнительныеПараметры.Лог;
	Если АнализируемыйФайл.Существует() И ЭтоФайлОписанияФормы(АнализируемыйФайл) Тогда
		
		Лог.Информация("Обработка файла '%1' по сценарию '%2'", АнализируемыйФайл.ПолноеИмя, ИмяСценария());
		
		Если ОбновитьИндексыЭлементовВФорме(АнализируемыйФайл.ПолноеИмя) Тогда

			ДополнительныеПараметры.ИзмененныеКаталоги.Добавить(АнализируемыйФайл.ПолноеИмя);

		КонецЕсли;

		Возврат ИСТИНА;
		
	КонецЕсли;

	Возврат ЛОЖЬ;

КонецФункции // ОбработатьФайл()

Функция ЭтоФайлОписанияФормы(Файл)
	
	Если ПустаяСтрока(Файл.Расширение) Тогда
		
		Возврат Ложь;
		
	КонецЕсли;
	
	Возврат СтрСравнить(Файл.Имя, "Form.xml") = 0;
	
КонецФункции

Функция ОбновитьИндексыЭлементовВФорме(Знач ИмяФайла)

	Текст = Новый ЧтениеТекста();
	Текст.Открыть(ИмяФайла, "utf-8");
	СодержимоеФайла = Текст.Прочитать();
	Текст.Закрыть();

	Регексп = Новый РегулярноеВыражение("id=\""([0-9-]+)\""\/*>");
	Регексп.ИгнорироватьРегистр = ИСТИНА;
	Регексп.Многострочный = ИСТИНА;
	ГруппыИндексов = Регексп.НайтиСовпадения(СодержимоеФайла);
	Если ГруппыИндексов.Количество() = 0 Тогда

		Возврат ЛОЖЬ;	

	КонецЕсли;

	ТЧ = Новый ТаблицаЗначений;
	ТЧ.Колонки.Добавить("Значение");
	ТЧ.Колонки.Добавить("Количество");

	СтрокиФайла = Новый Соответствие;
	Для Каждого ГруппаИндексов Из ГруппыИндексов Цикл

		СтрокаТЧ = ТЧ.ДОбавить();
		СтрокаТЧ.Значение = Число(ГруппаИндексов.Группы[1].Значение);
		СтрокаТЧ.Количество = 1;

		СтрокиФайла.Вставить(СтрокаТЧ.Значение, ГруппаИндексов.Группы[1].Индекс);

	КонецЦикла;

	ТЧ.Свернуть("Значение", "Количество");
	Если ТЧ.Количество() <> ГруппыИндексов.Количество() Тогда

		ТЧ.Сортировать("Значение УБЫВ");
		ПоследнийНомер = ТЧ[0].Значение;
		ТЧ.Сортировать("Количество УБЫВ");
		Для каждого СтрокаТЧ Из ТЧ Цикл
			
			Если СтрокаТЧ.Количество = 1 Тогда
			
				Прервать;
				
			КонецЕсли;
			
			Пока СтрокаТЧ.Количество > 1 Цикл

				ИсходнаяСтрока = "id=""" + СтрокаТЧ.Значение + """";
				ПоследнийНомер = ПоследнийНомер + 1;
				СтрокаЗамены = "id=""" + ПоследнийНомер + """";
	
				Поз = СтрНайти(СодержимоеФайла, ИсходнаяСтрока);
				
				НоваяСтрока = Лев(СодержимоеФайла, Поз - 1) + СтрокаЗамены;
				СодержимоеФайла = НоваяСтрока + Сред(СодержимоеФайла, Поз + СтрДлина(ИсходнаяСтрока));
	
				СтрокаТЧ.Количество = СтрокаТЧ.Количество - 1;
						
			КонецЦикла;

		КонецЦикла;

		ЗаписьТекста = Новый ЗаписьТекста(ИмяФайла,,,, Символы.ПС);
		ЗаписьТекста.Записать(СодержимоеФайла);
		ЗаписьТекста.Закрыть();

		Возврат ИСТИНА;
			
	КонецЕсли;

	Возврат ЛОЖЬ;
	
КонецФункции
