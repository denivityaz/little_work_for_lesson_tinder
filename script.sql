--таблица профилей с дополнительным полем для удаления профиля
CREATE TABLE profiles (
    id SERIAL PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    sex INTEGER,
    is_deleted BOOLEAN DEFAULT FALSE
);

-- таблица событий с внешними ключами и индексом
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    profile_from INTEGER NOT NULL,
    profile_to INTEGER NOT NULL,
    status INTEGER NOT NULL,
    FOREIGN KEY (profile_from) REFERENCES profiles(id) ON DELETE CASCADE,
    FOREIGN KEY (profile_to) REFERENCES profiles(id) ON DELETE CASCADE,
    CONSTRAINT unique_event_pair UNIQUE (profile_from, profile_to)
);

--таблица пар с ограничением уникальности и триггером для предотвращения перекрестных значений
CREATE TABLE pairs (
    id SERIAL PRIMARY KEY,
    profile1 INTEGER NOT NULL,
    profile2 INTEGER NOT NULL,
    slot INTEGER,
    FOREIGN KEY (profile1) REFERENCES profiles(id),
    FOREIGN KEY (profile2) REFERENCES profiles(id),
    CONSTRAINT unique_profile_pair UNIQUE (LEAST(profile1, profile2), GREATEST(profile1, profile2))
);

--триггер для проверки перекрестных значений
CREATE OR REPLACE FUNCTION prevent_cross_pairs()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pairs
        WHERE (NEW.profile1 = profile2 AND NEW.profile2 = profile1)
    ) THEN
        RAISE EXCEPTION 'Crossed profile pair not allowed';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_cross_pairs
BEFORE INSERT ON pairs
FOR EACH ROW
EXECUTE FUNCTION prevent_cross_pairs();

insert into profiles (first_name, last_name, sex) values
('1', '2', 0),
('3', '4', 1),
('6', '5', null),
('7', '6', null),
('9', '10', 0),
('11', '12', 0),
('13', '14', 1),
('15', '16', 1),
('17', '18', 0),
('18', '19', 1);

insert into events (profile_from, profile_to, status) values
(1, 2, 1),
(1, 5, 1),
(2, 1, 1),
(2, 5, 1),
(2, 7, 1),
(2, 3, 0),
(3, 9, 1),
(5, 1, 0),
(5, 2, 1),
(5, 6, 1),
(5, 8, 1),
(6, 8, 1),
(6, 5, 0),
(6, 7, 1),
(6, 10, 1),
(7, 3, 0),
(7, 9, 1),
(7, 10, 0),
(7, 6, 1),
(7, 5, 1),
(8, 1, 1),
(8, 5, 1),
(8, 6, 1),
(9, 3, 0),
(9, 10, 1),
(10, 7, 1),
(10, 9, 1),
(10, 6, 1);
