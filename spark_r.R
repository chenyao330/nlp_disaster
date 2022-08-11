library(sparklyr)
library(dplyr)
library(ggplot2)

spark_installed_versions()

#connect to local spark
sc <- spark_connect(master = "local", version = "2.3")

#copy dataset to spark
cars <- copy_to(sc, mtcars)

spark_web(sc)

count(cars)

cars %>% 
  select(hp, mpg) %>%
  sample_n(100) %>%
  collect() %>%
  plot()

model <- ml_linear_regression(cars, mpg ~ hp)
model

model %>%
  ml_predict(copy_to(sc, data.frame(hp = 250 + 10 * 1:10))) %>%
  transmute(hp = hp, mpg = prediction) %>%
  full_join(select(cars, hp, mpg)) %>%
  collect() %>%
  plot()

spark_write_csv(cars, "cars.csv")
cars <- spark_read_csv(sc, "cars.csv")

#apply r code to spark
cars %>% spark_apply(~round(.x))

#test screaming data
dir.create("input")
write.csv(mtcars, "input/cars_1.csv", row.names = F)

stream <- stream_read_csv(sc, "input/") %>%
  select(mpg, cyl, disp) %>%
  stream_write_csv("output/")
dir("output", pattern = ".csv")

# continue to put file in the input, and the stream read will output....
write.csv(mtcars, "input/cars_2.csv", row.names = F)

# stop stream
stream_stop(stream)

# retrieve log on local cluster
spark_log(sc)

# disconnect with spark
spark_disconnect(sc)


# directly pass the spark function as if it is an R function. 
# e.g. percentile is not a function in dplyr and array is a hive function
summarise(cars, mpg_percentile = percentile(mpg, array(0.25, 0.5, 0.75)))
summarise(cars, mpg_percentile = percentile(mpg, array(0.25, 0.5, 0.75))) %>% 
  show_query()

# use explode to store the result into a new column
summarise(cars, mpg_percentile = percentile(mpg, array(0.25, 0.5, 0.75))) %>%
  mutate(mpg_percentile = explode(mpg_percentile)) 

# corrr's backend used ml_corr, so no need to collect

ml_corr(cars)

library(corrr)
correlate(cars, use = "pairwise.complete.obs", method = "pearson")
correlate(cars, use = "pairwise.complete.obs", method = "pearson") %>%
  shave() %>%
  rplot()


# plot in R need to collect result from spark
# so, we can use dbplot
# dbplot is used to translate to spark and then plot using ggplot2
car_group <- cars %>%
  group_by(cyl) %>%
  summarise(mpg = sum(mpg, na.rm = TRUE)) %>%
  collect() %>%
  print()

ggplot(aes(as.factor(cyl), mpg), data = car_group) + 
  geom_col(fill = "#999999") + coord_flip()

library(dbplot)
cars %>%
  dbplot_histogram(mpg, binwidth = 3) +
  labs(title = "MPG Distribution",
       subtitle = "Histogram over miles per gallon")

# raster plot instead of a plot(no need to compute in spark)
# raster plot represent a x/y relationship
dbplot_raster(cars, mpg, wt, resolution = 16)


# caching data in spark rather than directly model
cached_cars <- cars %>% 
  mutate(cyl = paste0("cyl_", cyl)) %>%
  compute("cached_cars")

cached_cars %>%
  ml_linear_regression(mpg ~ .) %>%
  summary()

