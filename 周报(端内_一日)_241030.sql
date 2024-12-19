-- 周报活跃用户（端内 周一-周日维度）
WITH hy AS (
    SELECT
        weekofyear(date) AS 周数,
        COUNT(DISTINCT passenger_id) AS 活跃用户
    FROM idgadd_query.dwd_order_info
    WHERE
        event_day = DATE(date_sub(CURDATE(),INTERVAL 1 DAY))
        AND type = 1 AND task_purpose = 'publish'
        AND right(passenger_id,6) <> '000000'
        AND city_name = '武汉市'
        AND schedule_status IN (53,60)
        AND date BETWEEN DATE_SUB('2024-12-09',INTERVAL 28 DAY) AND DATE_SUB('2024-12-09',INTERVAL 1 DAY)
    GROUP BY 1
),
xk AS (
    SELECT
        weekofyear(first_finish_date) AS 周数,
        COUNT(DISTINCT passenger_id) AS 新客
    FROM idgadd_query.dwd_user_info
    WHERE
        event_day = DATE(date_sub(CURDATE(),INTERVAL 1 DAY))
        AND right(passenger_id,6) <> '000000'
        AND first_completed_city = '武汉市'
        AND first_finish_date BETWEEN DATE_SUB('2024-12-09',INTERVAL 28 DAY) and DATE_SUB('2024-12-09',INTERVAL 1 DAY)
    GROUP BY 1
),
lc AS (
    SELECT
        _b.week AS 周数,
        COUNT(DISTINCT _b.passenger_id) AS 留存用户
    FROM
        (
            select 
                weekofyear(date_format(date,'%Y-%m-%d')) as week,
                passenger_id
            from idgadd_query.dwd_order_info
            where 
                event_day = date_format(date_sub(now(), INTERVAL 1 DAY),'%Y-%m-%d')
                and type = 1 and task_purpose = 'publish'
                AND right(passenger_id,6) <> '000000'
                and schedule_status in (53,60)
                and city_name = '武汉市'
                and date between date_sub('2024-12-09',interval 14 day) and date_sub('2024-12-09',interval 8 day)
            group by 1,2
        ) _a 

        LEFT JOIN
        (
            select 
                weekofyear(date_format(date,'%Y-%m-%d')) as week,
                passenger_id
            from idgadd_query.dwd_order_info
            where 
                event_day = date_format(date_sub(now(), INTERVAL 1 DAY),'%Y-%m-%d')
                and type = 1 and task_purpose = 'publish' and schedule_status in (53,60)
                and city_name = '武汉市'
                and date between date_sub('2024-12-09',interval 7 day) and date_sub('2024-12-09',interval 1 day)
            group by 1,2
        ) _b 
    ON _a.passenger_id = _b.passenger_id
    GROUP BY 1
),
xklc AS (
    SELECT
        weekofyear(date_sub('2024-12-09',interval 7 day)) AS 周数,
        COUNT(DISTINCT _b.passenger_id) AS 新客留存 
    FROM
        (
            SELECT 
                DISTINCT passenger_id
            FROM idgadd_query.dwd_user_info
            WHERE
                event_day = date_format(date_sub(now(), INTERVAL 1 DAY),'%Y-%m-%d')
                AND right(passenger_id,6) <> '000000'
                and first_completed_city = '武汉市'
                AND first_finish_date between date_sub('2024-12-09',interval 14 day) and date_sub('2024-12-09',interval 8 day)
        ) _a

        LEFT JOIN
        (
            SELECT 
                DISTINCT passenger_id
            FROM idgadd_query.dwd_order_info
            WHERE
                event_day = date(DATE_SUB(now(),interval 1 day))
                and type = 1 and task_purpose = 'publish'
                and schedule_status in (53,60)
                and city_name = '武汉市'
                AND date between date_sub('2024-12-09',interval 7 day) and date_sub('2024-12-09',interval 1 day)
        ) _b 
    ON _a.passenger_id = _b.passenger_id
),
zh AS (
    SELECT
        weekofyear(date_sub('2024-12-09',interval 7 day)) AS 周数,
        COUNT(DISTINCT if(_b.passenger_id is NULL,_a.fm_passenger_id,NULL)) as 周期内所有沉默用户数,
        count(DISTINCT if(_b.passenger_id is NULL and _c.passenger_id IS NOT NULL,_a.passenger_id,NULL)) as 周期内所有被召回用户数
    FROM
        (
            SELECT 
                DISTINCT passenger_id,IF(city_name = '武汉市',passenger_id,NULL) AS fm_passenger_id
            FROM idgadd_query.dwd_order_info
            WHERE
                event_day = DATE_FORMAT(DATE_SUB(now(),INTERVAL 1 DAY),'%Y-%m-%d')
                and type = 1 and task_purpose = 'publish'
                AND right(passenger_id,6) <> '000000'
                and schedule_status in (53,60)
                and date < date_sub('2024-12-09',interval 14 day)
        ) _a 
        LEFT JOIN
        (
            SELECT 
                DISTINCT passenger_id
            FROM idgadd_query.dwd_order_info
            WHERE
                event_day = DATE_FORMAT(DATE_SUB(now(),INTERVAL 1 DAY),'%Y-%m-%d')
                and type = 1 and task_purpose = 'publish'
                AND right(passenger_id,6) <> '000000'
                and schedule_status in (53,60)
                and city_name = '武汉市'
                and date between date_sub('2024-12-09',interval 14 day) and date_sub('2024-12-09',interval 8 day)
        ) _b 
        on _a.passenger_id = _b.passenger_id
        
        LEFT JOIN
        (
            SELECT 
                DISTINCT passenger_id,date
            FROM idgadd_query.dwd_order_info
            WHERE
                event_day = DATE_FORMAT(DATE_SUB(now(),INTERVAL 1 DAY),'%Y-%m-%d')
                and type = 1 and task_purpose = 'publish'
                AND right(passenger_id,6) <> '000000'
                and schedule_status in (53,60)
                and city_name = '武汉市'
                and date between date_sub('2024-12-09',interval 7 day) and date_sub('2024-12-09',interval 1 day)
        ) _c 
        on _a.passenger_id = _c.passenger_id
    GROUP BY 1
)
SELECT
    hy.周数,
    hy.活跃用户,
    xk.新客,
    lc.留存用户,
    xklc.新客留存,
    zh.周期内所有被召回用户数,
    zh.周期内所有沉默用户数
FROM hy 
    LEFT JOIN xk ON hy.周数 = xk.周数
    LEFT JOIN lc ON hy.周数 = lc.周数
    LEFT JOIN xklc ON hy.周数 = xklc.周数
    LEFT JOIN zh ON hy.周数 = zh.周数
GROUP BY 1,2,3,4,5,6,7
ORDER BY 1
;


-- 新客渠道分析（周比周）
select 
    weekofyear(first_finish_date) as "周数",
    source as 渠道,
    count(distinct passenger_id)  as 新客
from 
    (
        SELECT
            first_finish_date,passenger_id,
            CASE
                WHEN user_source LIKE '其他' THEN '自然流量'
                WHEN user_source LIKE '百度地图聚合平台引流' THEN '百度地图'
                WHEN user_source LIKE '百度生态' THEN '百度小程序'
                WHEN user_source LIKE '助力活动' THEN '好友助力'
                WHEN user_source LIKE '微信朋友圈投放' THEN '朋友圈投放'
                WHEN user_source LIKE '微信生态' THEN '微信小程序'
                ELSE user_source
            END AS source
        FROM idgadd_query.dwd_user_info
        WHERE
            event_day = date_format(date_sub(now(), INTERVAL 1 DAY),'%Y-%m-%d')
            -- AND right(passenger_id,6) <> '000000'
            and first_completed_city = '武汉市'
            and first_finish_date between date_sub('2024-12-09',interval 56 day) and date_sub('2024-12-09',interval 1 day)
    ) _a 
group by 1,2
order by 1 desc,3 desc,2
;


-- 周报用券分布【刨除客服用券】周报新客用券情况分布
SELECT
    _a.source as 渠道,
    COUNT(DISTINCT if(_b.batch_id is not null,_b.passenger_id,null)) as 用券人数,
    COUNT(DISTINCT if( _b.batch_id is null,_a.passenger_id,null)) as 未用券人数,
    count(distinct _a.passenger_id) as 成单新客数
FROM
    (
        SELECT
            passenger_id,
            CASE
                WHEN user_source LIKE '其他' THEN '自然流量'
                WHEN user_source LIKE '百度地图聚合平台引流' THEN '百度地图'
                WHEN user_source LIKE '百度生态' THEN '百度小程序'
                WHEN user_source LIKE '助力活动' THEN '好友助力'
                WHEN user_source LIKE '微信朋友圈投放' THEN '朋友圈投放'
                WHEN user_source LIKE '微信生态' THEN '微信小程序'
                ELSE user_source
            END AS source
        FROM idgadd_query.dwd_user_info
        WHERE
            event_day = date_format(date_sub(now(), INTERVAL 1 DAY),'%Y-%m-%d')
            -- AND right(passenger_id,6) <> '000000'
            AND first_completed_city = '武汉市'
            AND first_finish_date between date_sub('2024-12-09',interval 7 day) and date_sub('2024-12-09',interval 1 day)
        GROUP BY 2,1
    ) _a 

    LEFT JOIN
        (
            SELECT
                passenger_id,batch_id
            from idgadd_query.dwd_coupon_info_qf
            where 
                event_day = concat(substring(date_sub(now(),interval 1 hour),1,13),':00:00')
                -- AND discount_type = 1
                AND coupons_status = 20
                AND use_date is not null
                AND batch_id NOT IN ('2635','2634','2633','1861','1043','1042','1041','1040','1039')
                AND date_format(use_date,'%Y-%m-%d') between date_sub('2024-12-09',interval 7 day) and date_sub('2024-12-09',interval 1 day)
            GROUP by 2,1
        ) _b 
    on _a.passenger_id = _b.passenger_id
group by 1
order by 4 desc
;


-- 新客周留存变化
SELECT
    _a.week AS 成单周次,
    _b.week_lc AS 留存周次,
    count(distinct _a.passenger_id) as 成单新客,
    sum(_b.sche) as 新客成单量
FROM
    (
        SELECT
            weekofyear(first_finish_date) as "week",
            passenger_id
        FROM idgadd_query.dwd_user_info
        where 
            event_day = date(date_sub(now(),interval 1 day))
            AND right(passenger_id,6) <> '000000'
            and first_completed_city = '武汉市'
            and first_finish_date BETWEEN DATE_SUB('2024-12-09',INTERVAL 56 DAY) and DATE_SUB('2024-12-09',INTERVAL 1 DAY)
        GROUP BY 1,2
    ) _a
    LEFT JOIN
    (
        SELECT
            weekofyear(date) as "week_lc",
            passenger_id as passenger,
            count(distinct schedule_id) as sche
        from idgadd_query.dwd_order_info 
        where 
            event_day = date(date_sub(now(),interval 1 day))
            and type = 1 and task_purpose = 'publish'
            and schedule_status in (53,60)
            AND city_name = '武汉市'
            and date BETWEEN DATE_SUB('2024-12-09',INTERVAL 56 DAY) and DATE_SUB('2024-12-09',INTERVAL 1 DAY)
        GROUP BY 1,2
    ) _b 
    ON _a.passenger_id = _b.passenger and _a.week <= _b.week_lc
GROUP BY 1,2
ORDER BY 1,2
;


-- 新客成单频次、客单价
SELECT
    _aa.week AS 周次,
    count(distinct _aa.passenger) as 新客用户数,
    count(distinct _aa.sche) as 新客成单量,
    (sum(_bb.pay_amount) / 1.09) as '券后收入(计收未税)',
    sum(_cc.coupon_money) as 新客成本,
    sum(_bb.pay_amount) as 券后收入,
    (sum(_bb.pay_amount) + sum(_cc.coupon_money)) as 券前收入,
    sum(_bb.received_amount) as 新客实收
FROM
    (
        SELECT
            DISTINCT _a.week,_b.passenger,_b.sche
        FROM
            (
                SELECT
                    weekofyear(first_finish_date) as "week",
                    passenger_id
                FROM idgadd_query.dwd_user_info
                where 
                    event_day = date(date_sub(now(),interval 1 day))
                    AND right(passenger_id,6) <> '000000'
                    and first_completed_city = '武汉市'
                    and first_finish_date BETWEEN DATE_SUB('2024-12-09',INTERVAL 56 DAY) and DATE_SUB('2024-12-09',INTERVAL 1 DAY)
                GROUP BY 1,2
            ) _a
            JOIN
            (
                SELECT
                    weekofyear(date) as "week_cd",
                    passenger_id as passenger,
                    schedule_id as sche
                from idgadd_query.dwd_order_info 
                where 
                    event_day = date(date_sub(now(),interval 1 day))
                    and type = 1 and task_purpose = 'publish' 
                    and schedule_status in (53,60)
                    AND city_name = '武汉市'
                    and date BETWEEN DATE_SUB('2024-12-09',INTERVAL 56 DAY) and DATE_SUB('2024-12-09',INTERVAL 1 DAY)
                GROUP BY 1,2,3
            ) _b 
        ON _a.passenger_id = _b.passenger and _a.week = _b.week_cd
    ) _aa 
    LEFT JOIN
    (
        SELECT
            schedule_id,
            sum(received_amount) / 100 as received_amount,
            sum(pay_amount_2) / 100 as pay_amount
        FROM idgadd_query.dwd_finance_info_new_df
        WHERE
            event_day = date_format(date_sub(now(), INTERVAL 1 DAY),'%Y-%m-%d')
            and is_commercial_order = 1
            and date BETWEEN DATE_SUB('2024-12-09',INTERVAL 56 DAY) and DATE_SUB('2024-12-09',INTERVAL 1 DAY)
        group by 1
    ) _bb 
    on _aa.sche = _bb.schedule_id
    LEFT JOIN
    (
        SELECT
            schedule_id,
            sum(coupon_money) as coupon_money
        FROM idgadd_query.dwd_coupon_info_qf
        where
            event_day = CONCAT(SUBSTRING(DATE_SUB(NOW(),INTERVAL 1 HOUR),1,11),'07:00:00')
            and date_format(bind_time,'%Y-%m-%d') BETWEEN DATE_SUB('2024-12-09',INTERVAL 56 DAY) and DATE_SUB('2024-12-09',INTERVAL 1 DAY)
        group by 1
    ) _cc 
    on _aa.sche = _cc.schedule_id
GROUP BY 周次
ORDER BY 周次
;


/*
-- 周报活跃用户（周一-周日维度）
WITH hy AS (
    SELECT
        weekofyear(date) AS 周数,
        COUNT(DISTINCT passenger_id) AS 活跃用户
    FROM idgadd_query.dwd_order_info
    WHERE
        event_day = DATE(date_sub(CURDATE(),INTERVAL 1 DAY))
        AND type = 1 AND task_purpose = 'publish'
        AND city_name = '武汉市'
        AND schedule_status IN (53,60)
        AND date BETWEEN DATE_SUB('2024-12-09',INTERVAL 56 DAY) AND DATE_SUB('2024-12-09',INTERVAL 1 DAY)
    GROUP BY 1
),
xk AS (
    SELECT
        weekofyear(first_finish_date) AS 周数,
        COUNT(DISTINCT passenger_id) AS 新客
    FROM idgadd_query.dwd_user_info
    WHERE
        event_day = DATE(date_sub(CURDATE(),INTERVAL 1 DAY))
        AND first_completed_city = '武汉市'
        AND first_finish_date BETWEEN DATE_SUB('2024-12-09',INTERVAL 56 DAY) and DATE_SUB('2024-12-09',INTERVAL 1 DAY)
    GROUP BY 1
),
lc AS (
    SELECT
        _b.week AS 周数,
        COUNT(DISTINCT _b.passenger_id) AS 留存用户
    FROM
        (
            select 
                weekofyear(date_format(date,'%Y-%m-%d')) as week,
                passenger_id
            from idgadd_query.dwd_order_info
            where 
                event_day = date_format(date_sub(now(), INTERVAL 1 DAY),'%Y-%m-%d')
                and type = 1 and task_purpose = 'publish' 
                and schedule_status in (53,60)
                and city_name = '武汉市'
                and date between date_sub('2024-12-09',interval 14 day) and date_sub('2024-12-09',interval 8 day)
            group by 1,2
        ) _a 

        LEFT JOIN
        (
            select 
                weekofyear(date_format(date,'%Y-%m-%d')) as week,
                passenger_id
            from idgadd_query.dwd_order_info
            where 
                event_day = date_format(date_sub(now(), INTERVAL 1 DAY),'%Y-%m-%d')
                and type = 1 and task_purpose = 'publish' 
                and schedule_status in (53,60)
                and city_name = '武汉市'
                and date between date_sub('2024-12-09',interval 7 day) and date_sub('2024-12-09',interval 1 day)
            group by 1,2
        ) _b 
    ON _a.passenger_id = _b.passenger_id
    GROUP BY 1
),
xklc AS (
    SELECT
        weekofyear(date_sub('2024-12-09',interval 7 day)) AS 周数,
        COUNT(DISTINCT _b.passenger_id) AS 新客留存 
    FROM
        (
            SELECT 
                DISTINCT passenger_id
            FROM idgadd_query.dwd_user_info
            WHERE
                event_day = date_format(date_sub(now(), INTERVAL 1 DAY),'%Y-%m-%d')
                and first_completed_city = '武汉市'
                AND first_finish_date between date_sub('2024-12-09',interval 14 day) and date_sub('2024-12-09',interval 8 day)
        ) _a

        LEFT JOIN
        (
            SELECT 
                DISTINCT passenger_id
            FROM idgadd_query.dwd_order_info
            WHERE
                event_day = date(DATE_SUB(now(),interval 1 day))
                and type = 1 and task_purpose = 'publish'
                and schedule_status in (53,60)
                and city_name = '武汉市'
                AND date between date_sub('2024-12-09',interval 7 day) and date_sub('2024-12-09',interval 1 day)
        ) _b 
    ON _a.passenger_id = _b.passenger_id
),
zh AS (
    SELECT
        weekofyear(date_sub('2024-12-09',interval 7 day)) AS 周数,
        COUNT(DISTINCT if(_b.passenger_id is NULL,_a.fm_passenger_id,NULL)) as 周期内所有沉默用户数,
        count(DISTINCT if(_b.passenger_id is NULL and _c.passenger_id IS NOT NULL,_a.passenger_id,NULL)) as 周期内所有被召回用户数
    FROM
        (
            SELECT 
                DISTINCT passenger_id,IF(city_name = '武汉市',passenger_id,NULL) AS fm_passenger_id
            FROM idgadd_query.dwd_order_info
            WHERE
                event_day = DATE_FORMAT(DATE_SUB(now(),INTERVAL 1 DAY),'%Y-%m-%d')
                and type = 1 and task_purpose = 'publish' 
                and schedule_status in (53,60)
                and date < date_sub('2024-12-09',interval 14 day)
        ) _a 
        LEFT JOIN
        (
            SELECT 
                DISTINCT passenger_id
            FROM idgadd_query.dwd_order_info
            WHERE
                event_day = DATE_FORMAT(DATE_SUB(now(),INTERVAL 1 DAY),'%Y-%m-%d')
                and type = 1 and task_purpose = 'publish' 
                and schedule_status in (53,60)
                and city_name = '武汉市'
                and date between date_sub('2024-12-09',interval 14 day) and date_sub('2024-12-09',interval 8 day)
        ) _b 
    on _a.passenger_id = _b.passenger_id
    LEFT JOIN
    (
        SELECT 
            DISTINCT passenger_id,date
        FROM idgadd_query.dwd_order_info
        WHERE
            event_day = DATE_FORMAT(DATE_SUB(now(),INTERVAL 1 DAY),'%Y-%m-%d')
            and type = 1 and task_purpose = 'publish' and schedule_status in (53,60)
            and city_name = '武汉市'
            and date between date_sub('2024-12-09',interval 7 day) and date_sub('2024-12-09',interval 1 day)
    ) _c 
    on _a.passenger_id = _c.passenger_id
    GROUP BY 1
)
SELECT
    hy.周数,
    hy.活跃用户,
    xk.新客,
    lc.留存用户,
    xklc.新客留存,
    zh.周期内所有被召回用户数,
    zh.周期内所有沉默用户数
FROM hy 
    LEFT JOIN xk ON hy.周数 = xk.周数
    LEFT JOIN lc ON hy.周数 = lc.周数
    LEFT JOIN xklc ON hy.周数 = xklc.周数
    LEFT JOIN zh ON hy.周数 = zh.周数
GROUP BY 1,2,3,4,5,6,7
ORDER BY 1
;