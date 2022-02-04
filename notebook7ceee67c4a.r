{
 "cells": [
  {
   "cell_type": "code",
   "execution_count": 1,
   "id": "b2e7cc9d",
   "metadata": {
    "_execution_state": "idle",
    "_uuid": "051d70d956493feee0c6d64651c6a088724dca2a",
    "execution": {
     "iopub.execute_input": "2022-02-04T01:35:06.591403Z",
     "iopub.status.busy": "2022-02-04T01:35:06.587303Z",
     "iopub.status.idle": "2022-02-04T01:35:07.942999Z",
     "shell.execute_reply": "2022-02-04T01:35:07.941944Z"
    },
    "papermill": {
     "duration": 1.369271,
     "end_time": "2022-02-04T01:35:07.943206",
     "exception": false,
     "start_time": "2022-02-04T01:35:06.573935",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "── \u001b[1mAttaching packages\u001b[22m ─────────────────────────────────────── tidyverse 1.3.1 ──\n",
      "\n",
      "\u001b[32m✔\u001b[39m \u001b[34mggplot2\u001b[39m 3.3.5     \u001b[32m✔\u001b[39m \u001b[34mpurrr  \u001b[39m 0.3.4\n",
      "\u001b[32m✔\u001b[39m \u001b[34mtibble \u001b[39m 3.1.5     \u001b[32m✔\u001b[39m \u001b[34mdplyr  \u001b[39m 1.0.7\n",
      "\u001b[32m✔\u001b[39m \u001b[34mtidyr  \u001b[39m 1.1.4     \u001b[32m✔\u001b[39m \u001b[34mstringr\u001b[39m 1.4.0\n",
      "\u001b[32m✔\u001b[39m \u001b[34mreadr  \u001b[39m 2.0.2     \u001b[32m✔\u001b[39m \u001b[34mforcats\u001b[39m 0.5.1\n",
      "\n",
      "── \u001b[1mConflicts\u001b[22m ────────────────────────────────────────── tidyverse_conflicts() ──\n",
      "\u001b[31m✖\u001b[39m \u001b[34mdplyr\u001b[39m::\u001b[32mfilter()\u001b[39m masks \u001b[34mstats\u001b[39m::filter()\n",
      "\u001b[31m✖\u001b[39m \u001b[34mdplyr\u001b[39m::\u001b[32mlag()\u001b[39m    masks \u001b[34mstats\u001b[39m::lag()\n",
      "\n"
     ]
    },
    {
     "data": {
      "text/html": [
       "'nlp-getting-started'"
      ],
      "text/latex": [
       "'nlp-getting-started'"
      ],
      "text/markdown": [
       "'nlp-getting-started'"
      ],
      "text/plain": [
       "[1] \"nlp-getting-started\""
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "library(tidyverse) # metapackage of all tidyverse packages\n",
    "\n",
    "# Input data files are available in the read-only \"../input/\" directory\n",
    "# For example, running this (by clicking run or pressing Shift+Enter) will list all files under the input directory\n",
    "\n",
    "list.files(path = \"../input\")\n",
    "\n",
    "# You can write up to 20GB to the current directory (/kaggle/working/) that gets preserved as output when you create a version using \"Save & Run All\" \n",
    "# You can also write temporary files to /kaggle/temp/, but they won't be saved outside of the current session"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 2,
   "id": "a21b2de0",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2022-02-04T01:35:08.024469Z",
     "iopub.status.busy": "2022-02-04T01:35:07.979613Z",
     "iopub.status.idle": "2022-02-04T01:35:08.166942Z",
     "shell.execute_reply": "2022-02-04T01:35:08.167708Z"
    },
    "papermill": {
     "duration": 0.20959,
     "end_time": "2022-02-04T01:35:08.167963",
     "exception": false,
     "start_time": "2022-02-04T01:35:07.958373",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/html": [
       "<table class=\"dataframe\">\n",
       "<caption>A data.frame: 6 × 5</caption>\n",
       "<thead>\n",
       "\t<tr><th></th><th scope=col>id</th><th scope=col>keyword</th><th scope=col>location</th><th scope=col>text</th><th scope=col>target</th></tr>\n",
       "\t<tr><th></th><th scope=col>&lt;int&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;int&gt;</th></tr>\n",
       "</thead>\n",
       "<tbody>\n",
       "\t<tr><th scope=row>1</th><td>1</td><td></td><td></td><td>Our Deeds are the Reason of this #earthquake May ALLAH Forgive us all                                                                </td><td>1</td></tr>\n",
       "\t<tr><th scope=row>2</th><td>4</td><td></td><td></td><td>Forest fire near La Ronge Sask. Canada                                                                                               </td><td>1</td></tr>\n",
       "\t<tr><th scope=row>3</th><td>5</td><td></td><td></td><td>All residents asked to 'shelter in place' are being notified by officers. No other evacuation or shelter in place orders are expected</td><td>1</td></tr>\n",
       "\t<tr><th scope=row>4</th><td>6</td><td></td><td></td><td>13,000 people receive #wildfires evacuation orders in California                                                                     </td><td>1</td></tr>\n",
       "\t<tr><th scope=row>5</th><td>7</td><td></td><td></td><td>Just got sent this photo from Ruby #Alaska as smoke from #wildfires pours into a school                                              </td><td>1</td></tr>\n",
       "\t<tr><th scope=row>6</th><td>8</td><td></td><td></td><td><span style=white-space:pre-wrap>#RockyFire Update =&gt; California Hwy. 20 closed in both directions due to Lake County fire - #CAfire #wildfires                       </span></td><td>1</td></tr>\n",
       "</tbody>\n",
       "</table>\n"
      ],
      "text/latex": [
       "A data.frame: 6 × 5\n",
       "\\begin{tabular}{r|lllll}\n",
       "  & id & keyword & location & text & target\\\\\n",
       "  & <int> & <chr> & <chr> & <chr> & <int>\\\\\n",
       "\\hline\n",
       "\t1 & 1 &  &  & Our Deeds are the Reason of this \\#earthquake May ALLAH Forgive us all                                                                 & 1\\\\\n",
       "\t2 & 4 &  &  & Forest fire near La Ronge Sask. Canada                                                                                                & 1\\\\\n",
       "\t3 & 5 &  &  & All residents asked to 'shelter in place' are being notified by officers. No other evacuation or shelter in place orders are expected & 1\\\\\n",
       "\t4 & 6 &  &  & 13,000 people receive \\#wildfires evacuation orders in California                                                                      & 1\\\\\n",
       "\t5 & 7 &  &  & Just got sent this photo from Ruby \\#Alaska as smoke from \\#wildfires pours into a school                                               & 1\\\\\n",
       "\t6 & 8 &  &  & \\#RockyFire Update => California Hwy. 20 closed in both directions due to Lake County fire - \\#CAfire \\#wildfires                        & 1\\\\\n",
       "\\end{tabular}\n"
      ],
      "text/markdown": [
       "\n",
       "A data.frame: 6 × 5\n",
       "\n",
       "| <!--/--> | id &lt;int&gt; | keyword &lt;chr&gt; | location &lt;chr&gt; | text &lt;chr&gt; | target &lt;int&gt; |\n",
       "|---|---|---|---|---|---|\n",
       "| 1 | 1 | <!----> | <!----> | Our Deeds are the Reason of this #earthquake May ALLAH Forgive us all                                                                 | 1 |\n",
       "| 2 | 4 | <!----> | <!----> | Forest fire near La Ronge Sask. Canada                                                                                                | 1 |\n",
       "| 3 | 5 | <!----> | <!----> | All residents asked to 'shelter in place' are being notified by officers. No other evacuation or shelter in place orders are expected | 1 |\n",
       "| 4 | 6 | <!----> | <!----> | 13,000 people receive #wildfires evacuation orders in California                                                                      | 1 |\n",
       "| 5 | 7 | <!----> | <!----> | Just got sent this photo from Ruby #Alaska as smoke from #wildfires pours into a school                                               | 1 |\n",
       "| 6 | 8 | <!----> | <!----> | #RockyFire Update =&gt; California Hwy. 20 closed in both directions due to Lake County fire - #CAfire #wildfires                        | 1 |\n",
       "\n"
      ],
      "text/plain": [
       "  id keyword location\n",
       "1 1                  \n",
       "2 4                  \n",
       "3 5                  \n",
       "4 6                  \n",
       "5 7                  \n",
       "6 8                  \n",
       "  text                                                                                                                                 \n",
       "1 Our Deeds are the Reason of this #earthquake May ALLAH Forgive us all                                                                \n",
       "2 Forest fire near La Ronge Sask. Canada                                                                                               \n",
       "3 All residents asked to 'shelter in place' are being notified by officers. No other evacuation or shelter in place orders are expected\n",
       "4 13,000 people receive #wildfires evacuation orders in California                                                                     \n",
       "5 Just got sent this photo from Ruby #Alaska as smoke from #wildfires pours into a school                                              \n",
       "6 #RockyFire Update => California Hwy. 20 closed in both directions due to Lake County fire - #CAfire #wildfires                       \n",
       "  target\n",
       "1 1     \n",
       "2 1     \n",
       "3 1     \n",
       "4 1     \n",
       "5 1     \n",
       "6 1     "
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "train = read.csv(\"../input/nlp-getting-started/train.csv\")\n",
    "test = read.csv(\"../input/nlp-getting-started/test.csv\")\n",
    "head(train)"
   ]
  },
  {
   "cell_type": "raw",
   "id": "5263bddc",
   "metadata": {
    "papermill": {
     "duration": 0.013958,
     "end_time": "2022-02-04T01:35:08.201199",
     "exception": false,
     "start_time": "2022-02-04T01:35:08.187241",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "train"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "R",
   "language": "R",
   "name": "ir"
  },
  "language_info": {
   "codemirror_mode": "r",
   "file_extension": ".r",
   "mimetype": "text/x-r-source",
   "name": "R",
   "pygments_lexer": "r",
   "version": "4.0.5"
  },
  "papermill": {
   "default_parameters": {},
   "duration": 5.250212,
   "end_time": "2022-02-04T01:35:08.326635",
   "environment_variables": {},
   "exception": null,
   "input_path": "__notebook__.ipynb",
   "output_path": "__notebook__.ipynb",
   "parameters": {},
   "start_time": "2022-02-04T01:35:03.076423",
   "version": "2.3.3"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
