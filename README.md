# TestVK

* Реализовала асинхронную загрузку аватарок пользователей и фотографий отзыва с помощью URLSession. Если изображение не удалось загрузить, используется фото-заглушка из Assets. 
P.S. ссылки на изображения, которые используются в проекте, работают с VPN.
* Для кэширования изображений использовала NSCache.
* Индикатор загрузки нарисовала свой (класс LoadingIndicator).
* Для многопоточности использовала GCD.
* Добавила экран просмотра фотографий с помощью UIPageViewController. 
