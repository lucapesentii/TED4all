###### TEDx-Load-Aggregate-Model ######

import sys
import json
import pyspark
from pyspark.sql.functions import col, collect_list, array_join, struct

from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

##### FROM FILES
tedx_dataset_path = "s3://tedx-data/final_list.csv"

###### READ PARAMETERS
args = getResolvedOptions(sys.argv, ['JOB_NAME'])

##### START JOB CONTEXT AND JOB
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

job = Job(glueContext)
job.init(args['JOB_NAME'], args)


#### READ INPUT FILES TO CREATE AN INPUT DATASET
tedx_dataset = spark.read \
    .option("header","true") \
    .option("quote", "\"") \
    .option("escape", "\"") \
    .csv(tedx_dataset_path)
   
tedx_dataset.printSchema()

#### FILTER ITEMS WITH NULL POSTING KEY
count_items = tedx_dataset.count()
count_items_null = tedx_dataset.filter("id is not null").count()
print(f"Number of items from RAW DATA {count_items}")
print(f"Number of items from RAW DATA with NOT NULL KEY {count_items_null}")


## READ THE DETAILS
details_dataset_path = "s3://tedx-data/details.csv"
details_dataset = spark.read \
    .option("header","true") \
    .option("quote", "\"") \
    .option("escape", "\"") \
    .csv(details_dataset_path)

details_dataset = details_dataset.select(col("id").alias("id_ref"),
                                         col("description"),
                                         col("duration"),
                                         col("publishedAt"),
                                         col("interalId"))

# AND JOIN WITH THE MAIN TABLE
tedx_dataset_main = tedx_dataset.join(details_dataset, tedx_dataset.id == details_dataset.id_ref, "left") \
    .drop("id_ref")

tedx_dataset_main.printSchema()


## READ THE IMAGES
images_dataset_path = "s3://tedx-data/images.csv"
images_dataset = spark.read \
    .option("header","true") \
    .option("quote", "\"") \
    .option("escape", "\"") \
    .csv(images_dataset_path)

# CREATE THE AGGREGATE MODEL
images_dataset = images_dataset.groupBy(col("id").alias("id_ref")).agg(collect_list("url").alias("url_images"))
#images_dataset = images_dataset.select(col("id").alias("id_ref"), \
#                                       col("url").alias("url_image"))

# AND JOIN WITH THE MAIN TABLE
tedx_dataset_main = tedx_dataset_main.join(images_dataset, tedx_dataset.id == images_dataset.id_ref, "left") \
    .drop("id_ref")

   
## READ TAGS DATASET
tags_dataset_path = "s3://tedx-data/tags.csv"
tags_dataset = spark.read.option("header","true").csv(tags_dataset_path)

# CREATE THE AGGREGATE MODEL
tags_dataset_agg = tags_dataset.groupBy(col("id").alias("id_ref")).agg(collect_list("tag").alias("tags"))

# AND JOIN WITH THE MAIN TABLE
tedx_dataset_agg = tedx_dataset_main.join(tags_dataset_agg, tedx_dataset.id == tags_dataset_agg.id_ref, "left") \
    .drop("id_ref")


# READ RELATED_VIDEOS DATASET
relatedvideo_dataset_path = "s3://tedx-data/related_videos.csv"
relatedvideo_dataset = spark.read.option("header","true").csv(relatedvideo_dataset_path)

relatedvideo_dataset = relatedvideo_dataset.drop("id")

rel_video_info = tedx_dataset_main.select(col("url"), \
                                          col("description"), \
                                          col("publishedAt"), \
                                          col("interalId"), \
                                          col("url_images"))

# ADD ALL INFORMATION OF EACH RELATED VIDEO                                        
relatedvideo_dataset = relatedvideo_dataset.join(rel_video_info, relatedvideo_dataset.related_id == rel_video_info.interalId, "left") 

# CREATE THE AGGREGATE MODEL
relatedvideo_dt = relatedvideo_dataset.groupBy(col("internalId").alias("id_from")).agg(collect_list(struct(col("title"), \
                                                                                                           col("presenterDisplayName").alias("speaker"), \
                                                                                                           col("duration"), \
                                                                                                           col("url"), \
                                                                                                           col("description"), \
                                                                                                           col("publishedAt"), \
                                                                                                           col("url_images"))).alias("related_videos"))

# AND JOIN WITH THE MAIN TABLE
tedx_dataset_agg = tedx_dataset_agg.join(relatedvideo_dt, tedx_dataset_agg.interalId == relatedvideo_dt.id_from, "left") \
    .select(col("id").alias("_id"), col("*")) \
    .drop("id_from") \
    .drop("id")

tedx_dataset_agg.printSchema()

write_mongo_options = {
    "connectionName": "TEDx2024",
    "database": "unibg_tedx_2024",
    "collection": "tedx_data10",
    "ssl": "true",
    "ssl.domain_match": "false"}
from awsglue.dynamicframe import DynamicFrame
tedx_dataset_dynamic_frame = DynamicFrame.fromDF(tedx_dataset_agg, glueContext, "nested")

glueContext.write_dynamic_frame.from_options(tedx_dataset_dynamic_frame, connection_type="mongodb", connection_options=write_mongo_options)